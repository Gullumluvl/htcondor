/***************************************************************
 *
 * Copyright (C) 1990-2007, Condor Team, Computer Sciences Department,
 * University of Wisconsin-Madison, WI.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License.  You may
 * obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ***************************************************************/


#include "condor_common.h"
#include "condor_debug.h"
#include "condor_daemon_core.h"
#include "daemon.h"
#include "dc_message.h"
#include "daemon_core_sock_adapter.h"

DCMsg::DCMsg(int cmd):
	m_cmd( cmd ),
	m_cmd_str( NULL ),
	m_msg_success_debug_level( D_FULLDEBUG ),
	m_msg_failure_debug_level( D_ALWAYS|D_FAILURE ),
	m_msg_cancel_debug_level( 0 ),
	m_delivery_status( DELIVERY_PENDING ),
	m_stream_type( Stream::reli_sock ),
	m_timeout( DEFAULT_CEDAR_TIMEOUT ),
	m_raw_protocol( false )
{
}

DCMsg::~DCMsg() {
}

void
DCMsg::setCallback(classy_counted_ptr<DCMsgCallback> cb)
{
	if( cb.get() ) {
		cb->setMessage( this );
	}
	m_cb = cb;
}

void
DCMsg::doCallback()
{
	if( m_cb.get() ) {
			// get rid of saved reference to callback object now, so it
			// can be garbage collected
		classy_counted_ptr<DCMsgCallback> cb = m_cb;
		m_cb = NULL;

		cb->doCallback();
	}
}

char const *
DCMsg::name()
{
	if( m_cmd_str ) {
		return m_cmd_str;
	}
	m_cmd_str = getCommandString( m_cmd );
	if( !m_cmd_str ) {
		m_cmd_str_buf.sprintf("command %d",m_cmd);
		m_cmd_str = m_cmd_str_buf.Value();
	}
	return m_cmd_str;
}

void
DCMsg::deliveryStatus(DeliveryStatus s)
{
		// if it was canceled, leave it canceled
	if( m_delivery_status != DELIVERY_CANCELED ) {
		m_delivery_status = s;
	}
}

void
DCMsg::setMessenger(DCMessenger *messenger)
{
	m_messenger = messenger;
}

void
DCMsg::cancelMessage()
{
	deliveryStatus( DELIVERY_CANCELED );
	addError( CEDAR_ERR_CANCELED, "operation was canceled" );

	if( m_messenger.get() ) {
		m_messenger->cancelMessage( this );
			// we now expect to be called via one of the message closure
			// functions: callMessageSendFailed(), callMessageReceiveFailed()
	}
}

void
DCMsg::callMessageSendFailed( DCMessenger *messenger )
{
	deliveryStatus( DELIVERY_FAILED );
	messageSendFailed( messenger );
	doCallback();
}

void
DCMsg::callMessageReceiveFailed( DCMessenger *messenger )
{
	deliveryStatus( DELIVERY_FAILED );
	messageReceiveFailed( messenger );
	doCallback();
}

DCMsg::MessageClosureEnum
DCMsg::callMessageSent(
				DCMessenger *messenger, Sock *sock )
{
	deliveryStatus( DELIVERY_SUCCEEDED );
	MessageClosureEnum closure = messageSent( messenger, sock );
	if( closure == MESSAGE_FINISHED ) {
		doCallback();
	}
	return closure;
}

DCMsg::MessageClosureEnum
DCMsg::callMessageReceived(
				DCMessenger *messenger, Sock *sock )
{
	deliveryStatus( DELIVERY_SUCCEEDED );
	MessageClosureEnum closure = messageReceived( messenger, sock );
	if( closure == MESSAGE_FINISHED ) {
		doCallback();
	}
	return closure;
}

DCMsg::MessageClosureEnum
DCMsg::messageSent( DCMessenger *messenger, Sock *)
{
	reportSuccess( messenger );

	return MESSAGE_FINISHED;
}

DCMsg::MessageClosureEnum
DCMsg::messageReceived( DCMessenger *messenger, Sock *)
{
	reportSuccess( messenger );

	return MESSAGE_FINISHED;
}

void
DCMsg::messageSendFailed( DCMessenger *messenger )
{
	reportFailure( messenger );
}

void
DCMsg::messageReceiveFailed( DCMessenger *messenger )
{
	reportFailure( messenger );
}

void
DCMsg::reportSuccess( DCMessenger *messenger )
{
	dprintf( m_msg_success_debug_level, "Completed %s to %s\n",
			 name(),
			 messenger->peerDescription() );
}

void
DCMsg::reportFailure( DCMessenger *messenger )
{
	int debug_level = m_msg_failure_debug_level;
	if( m_delivery_status == DELIVERY_CANCELED ) {
		debug_level = m_msg_cancel_debug_level;
	}
	dprintf( debug_level, "Failed to send %s to %s: %s\n",
			 name(),
			 messenger->peerDescription(),
			 m_errstack.getFullText() );
}

void
DCMsg::addError( int code, char const *format, ... )
{
	va_list args;
	va_start(args, format);

	MyString msg;
	msg.vsprintf( format,args );
	m_errstack.push( "CEDAR", code, msg.Value() );

	va_end(args);
}

void
DCMsg::sockFailed( Sock *sock )
{
		// TODO: get specific error message from sock, if possible
	if( sock->is_encode() ) {
		addError( CEDAR_ERR_PUT_FAILED, "failed writing to socket" );
	}
	else {
		addError( CEDAR_ERR_GET_FAILED, "failed reading from socket" );
	}
}


DCMessenger::DCMessenger( classy_counted_ptr<Daemon> daemon )
{
	m_daemon = daemon;
	m_sock = NULL;
	m_callback_msg = NULL;
	m_callback_sock = NULL;
	m_pending_operation = NOTHING_PENDING;
}

DCMessenger::DCMessenger( classy_counted_ptr<Sock> sock ):
	m_sock(sock)
{
	m_callback_msg = NULL;
	m_callback_sock = NULL;
	m_pending_operation = NOTHING_PENDING;
}

DCMessenger::~DCMessenger()
{
		// should never get deleted in the middle of a pending operation
	ASSERT(!m_callback_msg.get());
	ASSERT(!m_callback_sock);
	ASSERT(m_pending_operation == NOTHING_PENDING);
}

char const *DCMessenger::peerDescription()
{
	if( m_daemon.get() ) {
		return m_daemon->idStr();
	}
	if( m_sock.get() ) {
		return m_sock->peer_description();
	}
	EXCEPT("No daemon or sock object in DCMessenger::peerDescription()");
	return NULL;
}

void DCMessenger::startCommand( classy_counted_ptr<DCMsg> msg )
{
	MyString error;
	msg->setMessenger( this );

	if( msg->deliveryStatus() == DCMsg::DELIVERY_CANCELED ) {
		msg->callMessageSendFailed( this );
		return;
	}

		// For a UDP message, we may need to register two sockets, one for
		// the SafeSock and another for a ReliSock to establish the
		// security session.
	Stream::stream_type st = msg->getStreamType();
	if( daemonCoreSockAdapter.TooManyRegisteredSockets(-1,&error,st==Stream::safe_sock?2:1) ) {
			// Try again in a sec
			// Eventually, it would be better to queue this centrally
			// (i.e. in DaemonCore) rather than having an independent
			// timer for each case.  Then it would be possible to control
			// priority of different messages etc.
		dprintf(D_FULLDEBUG, "Delaying delivery of %s to %s, because %s\n",
				msg->name(),peerDescription(),error.Value());
		startCommandAfterDelay( 1, msg );
		return;
	}

		// Currently, there may be only one pending operation per messenger.
	ASSERT(!m_callback_msg.get());
	ASSERT(!m_callback_sock);
	ASSERT(m_pending_operation == NOTHING_PENDING);

	m_pending_operation = START_COMMAND_PENDING;
	m_callback_msg = msg;
	m_callback_sock = m_sock.get();
	if( !m_callback_sock ) {
		const bool nonblocking = true;
		m_callback_sock = m_daemon->makeConnectedSocket(st,msg->getTimeout(),&msg->m_errstack,nonblocking);
		if( !m_callback_sock ) {
			msg->callMessageSendFailed( this );
			return;
		}
	}

	incRefCount();
	m_daemon->startCommand_nonblocking (
		msg->m_cmd,
		m_callback_sock,
		msg->getTimeout(),
		&msg->m_errstack,
		&DCMessenger::connectCallback,
		this,
		msg->name(),
		msg->getRawProtocol(),
		msg->getSecSessionId());
}

void
DCMessenger::sendBlockingMsg( classy_counted_ptr<DCMsg> msg )
{
	msg->setMessenger( this );
	Sock *sock = m_daemon->startCommand (
		msg->m_cmd,
		msg->getStreamType(),
		msg->getTimeout(),
		&msg->m_errstack,
		msg->name(),
		msg->getRawProtocol(),
		msg->getSecSessionId());

	if( !sock ) {
		msg->callMessageSendFailed( this );
		return;
	}

	writeMsg( msg, sock );
}

void
DCMessenger::doneWithSock(Stream *sock)
{
		// If sock == m_sock, it will be cleaned up when the messenger
		// is deleted.  Otherwise, do it now.
	if( sock != m_sock.get() ) {
		if( sock ) {
			delete sock;
		}
	}
}

void
DCMessenger::connectCallback(bool success, Sock *sock, CondorError *, void *misc_data)
{
	ASSERT(misc_data);

	DCMessenger *self = (DCMessenger *)misc_data;
	classy_counted_ptr<DCMsg> msg = self->m_callback_msg;

	self->m_callback_msg = NULL;
	self->m_callback_sock = NULL;
	self->m_pending_operation = NOTHING_PENDING;

	if(!success) {
		msg->callMessageSendFailed( self );
		self->doneWithSock(sock);
	}
	else {
		ASSERT(sock);
		self->writeMsg( msg, sock );
	}

	self->decRefCount();
}

void DCMessenger::writeMsg( classy_counted_ptr<DCMsg> msg, Sock *sock )
{
	ASSERT( msg.get() );
	ASSERT( sock );

	msg->setMessenger( this );
	incRefCount();

		/* Some day, we may send message asynchronously and call
		   messageSent() later, after the delivery.  For now, we do it
		   all synchronously, right here. */

	sock->encode();

	if( msg->deliveryStatus() == DCMsg::DELIVERY_CANCELED ) {
		msg->callMessageSendFailed( this );
		doneWithSock(sock);
	}
	else if( !msg->writeMsg( this, sock ) ) {
		msg->callMessageSendFailed( this );
		doneWithSock(sock);
	}
	else if( !sock->eom() ) {
		msg->addError( CEDAR_ERR_EOM_FAILED, "failed to send EOM" );
		msg->callMessageSendFailed( this );
		doneWithSock(sock);
	}
	else {
			// Success
		DCMsg::MessageClosureEnum closure = msg->callMessageSent( this, sock );

		switch( closure ) {
		case DCMsg::MESSAGE_FINISHED:
			doneWithSock(sock);
			break;
		case DCMsg::MESSAGE_CONTINUING:
			break;
		}
	}

	decRefCount();
}

void DCMessenger::startReceiveMsg( classy_counted_ptr<DCMsg> msg, Sock *sock )
{
		// Currently, only one pending message per messenger.
	ASSERT( !m_callback_msg.get() );
	ASSERT( !m_callback_sock );
	ASSERT( m_pending_operation == NOTHING_PENDING );

	msg->setMessenger( this );

	MyString name;
	name.sprintf("DCMessenger::receiveMsgCallback %s", msg->name());

	incRefCount();

	int reg_rc = daemonCoreSockAdapter.
		Register_Socket( sock, peerDescription(),
						 (SocketHandlercpp)&DCMessenger::receiveMsgCallback,
						 name.Value(), this, ALLOW );
	if(reg_rc < 0) {
		msg->addError(
			CEDAR_ERR_REGISTER_SOCK_FAILED,
			"failed to register socket (Register_Socket returned %d)",
			reg_rc );
		msg->callMessageReceiveFailed( this );
		doneWithSock(sock);
		decRefCount();
		return;
	}

	m_callback_msg = msg; // prevent msg from going out of reference
	m_callback_sock = sock;
	m_pending_operation = RECEIVE_MSG_PENDING;
}

int
DCMessenger::receiveMsgCallback(Stream *sock)
{
	classy_counted_ptr<DCMsg> msg = m_callback_msg;
	ASSERT(msg.get());

	m_callback_msg = NULL;
	m_callback_sock = NULL;
	m_pending_operation = NOTHING_PENDING;

	daemonCoreSockAdapter.Cancel_Socket( sock );

	ASSERT( sock );
	readMsg( msg, (Sock *)sock );

	decRefCount();
	return KEEP_STREAM;
}

void
DCMessenger::readMsg( classy_counted_ptr<DCMsg> msg, Sock *sock )
{
	ASSERT( msg.get() );
	ASSERT( sock );

	msg->setMessenger( this );

	incRefCount();

	sock->decode();

	bool done_with_sock = true;

	if( msg->deliveryStatus() == DCMsg::DELIVERY_CANCELED ) {
		msg->callMessageReceiveFailed( this );
	}
	else if( !msg->readMsg( this, sock ) ) {
		msg->callMessageReceiveFailed( this );
	}
	else if( !sock->eom() ) {
		msg->addError( CEDAR_ERR_EOM_FAILED, "failed to read EOM" );
		msg->callMessageReceiveFailed( this );
	}
	else {
			// Success
		DCMsg::MessageClosureEnum closure = msg->callMessageReceived( this, sock );

		if( closure == DCMsg::MESSAGE_CONTINUING ) {
			done_with_sock = false;
		}
	}

	if( done_with_sock ) {
		doneWithSock( sock );
	}

	decRefCount();
}

void
DCMessenger::cancelMessage( classy_counted_ptr<DCMsg> msg )
{
	if( msg.get() != m_callback_msg.get() ) {
		return;
	}

	if( m_pending_operation == NOTHING_PENDING ) {
		return;
	}

	if( m_callback_sock && m_callback_sock->get_file_desc() != INVALID_SOCKET ) {
		m_callback_sock->close();
			// force callback now so everything gets cleaned up properly
		daemonCoreSockAdapter.CallSocketHandler( m_callback_sock );
	}
}


struct QueuedCommand {
	classy_counted_ptr<DCMsg> msg;
	int timer_handle;
};

void
DCMessenger::startCommandAfterDelay( unsigned int delay, classy_counted_ptr<DCMsg> msg )
{
	QueuedCommand *qc = new QueuedCommand;
	qc->msg = msg;

	incRefCount();
	qc->timer_handle = daemonCoreSockAdapter.Register_Timer(
		delay,
		(Eventcpp)&DCMessenger::startCommandAfterDelay_alarm,
		"DCMessenger::startCommandAfterDelay",
		this );
	ASSERT(qc->timer_handle != -1);
	daemonCoreSockAdapter.Register_DataPtr( qc );
}

int DCMessenger::startCommandAfterDelay_alarm()
{
	QueuedCommand *qc = (QueuedCommand *)daemonCoreSockAdapter.GetDataPtr();
	ASSERT(qc);

	startCommand(qc->msg);

	delete qc;
	decRefCount();

	return TRUE;
}

DCCommandOnlyMsg::DCCommandOnlyMsg( int cmd ): DCMsg( cmd )
{
}

bool DCCommandOnlyMsg::writeMsg( DCMessenger *, Sock * )
{
	return true;
}

bool DCCommandOnlyMsg::readMsg( DCMessenger *, Sock * )
{
	return true;
}

DCStringMsg::DCStringMsg( int cmd, char const *str ):
	DCMsg( cmd )
{
	m_str = str;
}

bool DCStringMsg::writeMsg( DCMessenger *, Sock *sock )
{
	if( !sock->put( m_str.Value() ) ) {
		sockFailed( sock );
		return false;
	}
	return true;
}

bool DCStringMsg::readMsg( DCMessenger *, Sock *sock )
{
	char *str = NULL;
	if( !sock->get( str ) ){
		sockFailed( sock );
		return false;
	}
	m_str = str;
	free(str);

	return true;
}

void
DCMsgCallback::doCallback()
{
	if( m_fn_cpp ) {
		(m_service->*m_fn_cpp)(this);
	}
}

DCMsgCallback::DCMsgCallback(CppFunction fn,Service *service,void *misc_data)
{
	m_fn_cpp = fn;
	m_service = service;
	m_misc_data = misc_data;
}

void
DCMsgCallback::cancelMessage()
{
	if( m_msg.get() ) {
		m_msg->cancelMessage();
	}
}

void
DCMsgCallback::cancelCallback()
{
	m_fn_cpp = NULL;
	m_service = NULL;
	m_misc_data = NULL;
}

ClassAdMsg::ClassAdMsg(int cmd,ClassAd &msg):
	DCMsg(cmd),
	m_msg(msg)
{
}

bool
ClassAdMsg::writeMsg( DCMessenger * /*messenger*/, Sock *sock )
{
	return m_msg.put( *sock );
}

bool
ClassAdMsg::readMsg( DCMessenger * /*messenger*/, Sock *sock )
{
	return m_msg.initFromStream( *sock );
}
