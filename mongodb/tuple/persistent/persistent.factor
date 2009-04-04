USING: accessors assocs classes fry kernel linked-assocs math mirrors
namespaces sequences strings vectors words bson.constants 
continuations mongodb.driver mongodb.tuple.collection mongodb.tuple.state ;

IN: mongodb.tuple.persistent

SYMBOL: mdb-store-list

GENERIC: tuple>assoc ( tuple -- assoc )

GENERIC: tuple>selector ( tuple -- selector )

DEFER: assoc>tuple
DEFER: mdb-persistent?

<PRIVATE

: mdbinfo>tuple-class ( tuple-info -- class )
    [ first ] keep second lookup ; inline

: tuple-instance ( tuple-info -- instance )
    mdbinfo>tuple-class new ; inline 

: [keys>tuple] ( mirror assoc -- quot: ( elt -- ) )
   '[ dup _ at assoc>tuple swap _ set-at ] ;  

: prepare-assoc>tuple ( assoc -- tuple keylist mirror assoc )
   [ tuple-info tuple-instance dup
     <mirror> [ keys ] keep ] keep swap ; inline

: make-tuple ( assoc -- tuple )
   prepare-assoc>tuple [keys>tuple] each
   [ set-persistent ] keep ; inline 

: at+ ( value key assoc -- value )
    2dup key?
    [ at nip ] [ [ dup ] 2dip set-at ] if ; inline

: data-tuple? ( tuple -- ? )
    dup tuple?
    [ assoc? not ] [ drop f ] if  ; inline

: add-storable ( assoc ns -- )
   [ H{ } clone ] dip mdb-store-list get at+
   [ dup [ MDB_OID_FIELD ] dip at ] dip set-at ; inline
 
: write-tuple-fields ( mirror assoc conv-quot -- )
   swap [ dup ] dip ! m a a q
   '[ [ dup mdb-persistent?
        [ _ keep
          [ tuple-collection ] keep
          [ add-storable ] dip
          [ tuple-collection ] [ _id>> ] bi <objref> ]
        [ dup data-tuple? _ [ ] if ] if _ set-at ] [ drop ] if*
   ] assoc-each ; 

: prepare-assoc ( tuple -- assoc mirror assoc )
   <mirror> H{ } clone tuck ; inline

: ensure-mdb-info ( tuple -- tuple )    
   dup _id>> [ <objid> >>_id ] unless
   [ set-persistent ] keep ; inline

: with-store-list ( quot: ( -- ) -- store-assoc )
   [ H{ } clone dup mdb-store-list ] dip with-variable ; inline

: (tuple>assoc) ( tuple -- assoc )
   [ prepare-assoc [ tuple>assoc ] write-tuple-fields ] keep
   over set-tuple-info ;

PRIVATE>

GENERIC: tuple>storable ( tuple -- storable ) 
M: mdb-persistent tuple>storable ( mdb-persistent -- store-list )
   '[ _ [ tuple>assoc ] keep tuple-collection add-storable ] with-store-list ; inline

M: mdb-persistent tuple>assoc ( tuple -- assoc )
   ensure-mdb-info (tuple>assoc) ;

M: tuple tuple>assoc ( tuple -- assoc )
   (tuple>assoc) ;

M: tuple tuple>selector ( tuple -- assoc )
    prepare-assoc [ tuple>selector ] write-tuple-fields ;

: assoc>tuple ( assoc -- tuple )
    dup assoc?
    [ [ dup tuple-info?
        [ make-tuple ]
        [ ] if ] [ drop ] recover
    ] [ ] if ; inline

