# This is a submit host image for HTCondor with a single user for submission
ARG EL
ARG VERSION

FROM htcondor/base:${VERSION}-el${EL}

ARG EL
ARG SERIES
ARG BUILDDATE

# https://label-schema.org/rc1
LABEL org.label-schema.name="htcondor/submit:${VERSION}-el${EL}" \
      org.label-schema.description="HTCondor ${VERSION} submit host image for RHEL ${EL}-compatible" \
      org.label-schema.vendor="HTCondor" \
      org.label-schema.license="Apache-2.0"

# Add a test submitter user
RUN useradd submituser

COPY submit/condor/*.conf /etc/condor/config.d/

EXPOSE 9618

LABEL org.label-schema.build-date="${BUILDDATE}"
