#ifndef _Collections_H
#define _Collections_H

//-------------------------------------------------------------------------

#include "condor_classad.h"
#include "Set.h"
#include "MyString.h"

//-------------------------------------------------------------------------

class RankedClassAd {

public:

  RankedClassAd() { Rank=0.0; }
  RankedClassAd(const MyString& oid) { OID=oid; Rank=0.0; }
  RankedClassAd(const MyString& oid, float rank) { OID=oid; Rank=rank; }
  MyString OID;
  float Rank;
  friend bool operator==(const RankedClassAd& RankedAd1, const RankedClassAd& RankedAd2) {
    return ((RankedAd1.OID==RankedAd2.OID) ? true : false);
  }

  friend bool operator!=(const RankedClassAd& RankedAd1, const RankedClassAd& RankedAd2) {
    return ((RankedAd1.OID==RankedAd2.OID) ? false : true);
  }

};

//-------------------------------------------------------------------------
// Collection Hierarchy
//-------------------------------------------------------------------------

typedef Set<MyString> StringSet;
typedef Set<int> IntegerSet;
typedef Set<RankedClassAd> RankedAdSet;

enum CollectionType { ExplicitCollection_e, ConstraintCollection_e, PartitionParent_e, PartitionChild_e };

//-------------------------------------------------------------------------

class BaseCollection {

public:
	virtual ~BaseCollection(){};

  BaseCollection(const MyString& rank) {
    Rank=rank;
  }

  virtual bool CheckClassAd(ClassAd* Ad)=0;

  virtual int Type()=0;

  MyString GetRank() { return Rank; }
  
  IntegerSet Children;
  RankedAdSet Members;

  MyString Rank;

};

//-------------------------------------------------------------------------

class ExplicitCollection : public BaseCollection {

public:
	virtual ~ExplicitCollection(){};

  ExplicitCollection(const MyString& rank, bool fullFlag) 
  : BaseCollection(rank) {
    FullFlag=fullFlag;
  }

  virtual bool CheckClassAd(ClassAd* Ad) {
    return FullFlag;
  }

  virtual int Type() { return ExplicitCollection_e; }

  bool FullFlag;

};

//-------------------------------------------------------------------------

class ConstraintCollection : public BaseCollection {

public:
	virtual ~ConstraintCollection(){};

  ConstraintCollection(const MyString& rank, const MyString& constraint)
  : BaseCollection(rank) {
    Constraint=constraint;
  }
  
  virtual bool CheckClassAd(ClassAd* Ad) {
    ExprTree* tree;
    EvalResult result;

    if (Parse(Constraint.Value(), tree) != 0) {
        return false;
    }

    if (!tree->EvalTree(NULL, Ad, &result)) {
        delete tree;
        return false;
    }

    delete tree;
    if (result.type == LX_INTEGER) {
        return (bool)result.i;
    }

    return false;
  }

  virtual int Type() { return ConstraintCollection_e; }

  MyString Constraint;

};

//-------------------------------------------------------------------------

class PartitionParent : public BaseCollection {

public:

	virtual ~PartitionParent(){};
  PartitionParent(const MyString& rank, StringSet& attributes)
  : BaseCollection(rank) {
    Attributes=attributes;
  }

  virtual bool CheckClassAd(ClassAd* Ad) {
    return false;
  }

  virtual int Type() { return PartitionParent_e; }

  StringSet Attributes;

};

//-------------------------------------------------------------------------

class PartitionChild : public BaseCollection {

public:
	virtual ~PartitionChild(){};

  PartitionChild(const MyString& rank, StringSet& values)
  : BaseCollection(rank) {
    Values=values;
  }

  virtual bool CheckClassAd(ClassAd* Ad) {
    return true;
  }

  virtual int Type() { return PartitionChild_e; }

  StringSet Values;

};

//-------------------------------------------------------------------------

#endif
