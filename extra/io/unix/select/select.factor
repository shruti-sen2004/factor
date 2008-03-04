! Copyright (C) 2004, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: alien.c-types kernel io.nonblocking io.unix.backend
bit-arrays sequences assocs unix math namespaces structs ;
IN: io.unix.select

TUPLE: select-mx read-fdset write-fdset ;

! Factor's bit-arrays are an array of bytes, OS X expects
! FD_SET to be an array of cells, so we have to account for
! byte order differences on big endian platforms
: munge ( i -- i' )
    little-endian? [ BIN: 11000 bitxor ] unless ; inline

: <select-mx> ( -- mx )
    select-mx construct-mx
    FD_SETSIZE 8 * <bit-array> over set-select-mx-read-fdset
    FD_SETSIZE 8 * <bit-array> over set-select-mx-write-fdset ;

: clear-nth ( n seq -- ? )
    [ nth ] 2keep f -rot set-nth ;

: handle-fd ( fd task fdset mx -- )
    roll munge rot clear-nth
    [ swap handle-io-task ] [ 2drop ] if ;

: handle-fdset ( tasks fdset mx -- )
    [ handle-fd ] 2curry assoc-each ;

: init-fdset ( tasks fdset -- )
    ! dup clear-bits
    [ >r drop t swap munge r> set-nth ] curry assoc-each ;

: read-fdset/tasks
    { mx-reads select-mx-read-fdset } get-slots ;

: write-fdset/tasks
    { mx-writes select-mx-write-fdset } get-slots ;

: max-fd dup assoc-empty? [ drop 0 ] [ keys supremum ] if ;

: num-fds ( mx -- n )
    dup mx-reads max-fd swap mx-writes max-fd max 1+ ;

: init-fdsets ( mx -- nfds read write except )
    [ num-fds ] keep
    [ read-fdset/tasks tuck init-fdset ] keep
    write-fdset/tasks tuck init-fdset
    f ;

M: select-mx wait-for-events ( ms mx -- )
    swap >r dup init-fdsets r> dup [ make-timeval ] when
    select multiplexer-error
    dup read-fdset/tasks pick handle-fdset
    dup write-fdset/tasks rot handle-fdset ;
