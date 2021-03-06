      SUBROUTINE PRES3E(MCOLOR,MCPART,NCOLOR,NCPART,LLOOP,
     *                  ME,N,N1,NEX,NE,NP,
     *                  MRCM,NMAX,NMAXB,ISOLP,
     *                  EPS,EPSRE,DT3D,
     *                  NODE,CM,SN,DNXYZ,DNXI,DNYI,DNZI,
     *                  U,V,W,NPINLT,LPINLT,NPMWAL,LPMWAL,
     *                  NPSYMT,LPSYMT,XPSYMT,YPSYMT,ZPSYMT,
     *                  NITR,RES,PE,PN,
     *                  IPART,NDOM,MBPDOM,LDOM,NBPDOM,IPSLF,IPSND,
     *                  LPFIX,LFIX3D,FXYZ,WRK01,WRK02,WRK03,WRK04,
     *                  WRK05,WRK06,WRK07,WRK08,WRK09,B,
     *                  PRCM,APRCM,RX,RY,MWRK,WRKN,
     *                  IUT0,IERR)
#include "timing.h"
      IMPLICIT NONE
C
CCC   [INPUT]
      INTEGER*4 MCOLOR,MCPART
      INTEGER*4 NCOLOR(4),NCPART(MCOLOR,4),LLOOP(MCPART,MCOLOR,4)
      INTEGER*4 ME,N,N1,NEX(8),NE,NP,NMAX,IUT0
      INTEGER*4 MRCM,NMAXB,ISOLP
      REAL*4    EPS,EPSRE,DT3D(NE)
      INTEGER*4 NODE(N1,NE),
     *          NPINLT,LPINLT(NPINLT),NPSYMT,LPSYMT(NPSYMT),
     *          NPMWAL,LPMWAL(NPMWAL)
      REAL*4    CM(NP),SN(N1,ME),
     *          DNXYZ(3,N1,ME),
     *          DNXI(N1,ME),DNYI(N1,ME),DNZI(N1,ME),
     *          U(NP),V(NP),W(NP)
      REAL*4    XPSYMT(NPSYMT),YPSYMT(NPSYMT),ZPSYMT(NPSYMT)
      INTEGER*4 IPART,NDOM,MBPDOM,
     *          LDOM(NDOM),NBPDOM(NDOM),
     *          IPSLF(MBPDOM,NDOM),IPSND(MBPDOM,NDOM)
C
CCC [INPUT/OUTPUT]
      REAL*4    PE(NE)
C
CCC [OUTPUT]
      INTEGER*4 NITR,IERR
      REAL*4    RES,PN(NP)
C
CCC [WORK]
      INTEGER*4 LPFIX(NP),LFIX3D(NP)
      REAL*4    RX(0:N,ME),RY(0:N,ME),
     *          B(NE),FXYZ(3,NP),
     *          WRK01(*),WRK02(*),WRK03(*),WRK04(*),
     *          WRK05(*),WRK06(*),WRK07(*),WRK08(*),
     *          WRK09(*)
      REAL*4    PRCM(MRCM,NE),APRCM(MRCM,NE)
      INTEGER*4 MWRK
      REAL*4    WRKN(MWRK,9)
C      
C     [IN:MID NODE COLORING]
C
CCCC  [LOCAL]
      INTEGER*4 IBP,NPFIX,MAXBUF,IP,IE
C
      REAL*4    EPS0 
      DATA EPS0 / 1.E-30 /
C
      CHARACTER*60 ERMSGC
     & /' ## SUBROUTINE PRES3E: FATAL      ERROR REPORT   ; RETURNED' /
C
C     SOLVE CONTINUITY EQUATION DEFINED AT ELEMENTS 
C 
C     WRITTEN BY Y.YAMADE 2011.01.20
C    
C     NOTE THAT 
C     CURRENT VERSION DOES NOT SUPPORT OVERSET AND MID-NODES
C
C     ARGUMENT LISTINGS
C (1) INPUT
C INT *4 N            ; MAX. NUMBER OF NODES ASSIGNED TO ONE ELEMENT (=8)
C INT *4 N1           ; THE DIMENSION SIZE OF THE FIRST ELEMENTS OF THE 
C                       PASSED ARRAYS 'NODET'
C INT *4 NE           ; NUMBER OF ELEMENTS
C INT *4 NP           ; NUMBER OF NODES
C INT *4 NEX       (I); INCLUDES NUMBER OF ELEMENTS AND NUMBER OF LOCAL NODES
C INT *4 NE           ; NUMBER OF ELEMENTS
C INT *4 NP           ; NUMBER OF NODES
C INT *4 NMAX         ; NUMBER OF MATRIX SOLVER ITERATIONS
C INT *4 IUT0         ; FILE NUMBER TO REPORT ERROR OCCURENCE
C REAL*4 EPS          ; MAXIMUM ALLOWABLE ERROR
C INT *4 NODE   (I,IE); NODE TABLE
C INT *4 NPINLT       ; NUMBER OF INLET BOUNDARY NODES
C INT *4 LPINLT   (IB); INLET BOUNDARY NODES
C INT *4 NPMWAL       ; NUMBER OF MOVING-WALL BOUNDARY NODES
C INT *4 LPMWAL   (IB); MOVING-WAL BOUNDARU NODES
C REAL*4 CM       (IP); INVERSED LUMPED MASS MATRIX
C REAL*4 SN     (I,IE); INTEGRATED ELEMENT VECTOR OF N
C REAL*4 DNX    (I,IE); ELEMENT CENTER VALUE OF NX
C REAL*4 DNY    (I,IE); ELEMENT CENTER VALUE OF NY
C REAL*4 DNZ    (I,IE); ELEMENT CENTER VALUE OF NZ
C REAL*4 DNXI   (I,IE); ELEMENT CENTER VALUE OF NX
C REAL*4 DNYI   (I,IE); ELEMENT CENTER VALUE OF NX
C REAL*4 DNZI   (I,IE); ELEMENT CENTER VALUE OF NX
C REAL*4 U        (IP); X-DIR. VELOCITY COMPONENT
C REAL*4 V        (IP); Y-DIR. VELOCITY COMPONENT
C REAL*4 W        (IP); Z-DIR. VELOCITY COMPONENT
C 
C (2) INPUT/OUTPUT
C REAL*4 PE       (IE); PRESSURE AT ELEMENTS
C
C (3) OUTPUT
C INT *4 NITR         ; ITERATION NUMBER OF MATRIX SOLVER
C REAL*4 RES          ; L2-NORM RESIDUAL OF THE FINAL SOLUTION VECTOR
C REAL*4 PN       (IP); PRESSURE AT NODES
C INT *4 IERR         ; RETURN CODE TO REPORT ERROR OCCURENCE
C                   0 --- NORMAL TERMINATION
C                   1 --- A FATAL ERROR HAS OCCURED
C
C (4) WORK
C REAL*4 RX     (I,IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 RY     (I,IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 B        (IE); WORK REGION PASSED FOR R.H.S. VECTOR 
C REAL*4 WRK01    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK02    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK03    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK04    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK05    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK06    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK07    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK08    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C REAL*4 WRK09    (IE); WORK REGION PASSED FOR MATRIX SOLVER
C
      IERR=0
      MAXBUF=NE*(N+1)
C
      DO 1000 IP=1,NP
          LFIX3D(IP)=0
 1000 CONTINUE   
C
!ocl norecurrence(LFIX3D)
      DO 1100 IBP=1,NPINLT
          IP=LPINLT(IBP)
          LFIX3D(IP)=1
 1100 CONTINUE   
C
!ocl norecurrence(LFIX3D)
      DO 1200 IBP=1,NPMWAL
          IP=LPMWAL(IBP)
          LFIX3D(IP)=1
 1200 CONTINUE   
C
      NPFIX=0
      DO 1450 IP=1,NP
          IF(LFIX3D(IP).EQ.0) GOTO 1450
          NPFIX=NPFIX+1
          LPFIX(NPFIX)=IP
 1450 CONTINUE 
C
      CALL FILD3X(ME,NE,NP,NEX,N1,
     *            U,V,W,B,NODE,DNXI,DNYI,DNZI)
      IF(IERR.NE.0) THEN
          WRITE(IUT0,*) ERMSGC
          RETURN
      ENDIF
C
      DO 1550 IE=1,NE
          B(IE)=B(IE)/DT3D(IE)
 1550 CONTINUE
C
C
      IF(ISOLP.EQ.1) THEN
          TIME_START(TM_BCGSXE)
          CALL BCGSXE(MCOLOR,MCPART,NCOLOR,NCPART,LLOOP,
     *                ME,N,N1,NEX,NE,NP,NMAX,EPS,EPSRE,
     *                NODE,CM,DNXYZ,DNXI,DNYI,DNZI,
     *                B,NPFIX,LPFIX,
     *                NPSYMT,LPSYMT,XPSYMT,YPSYMT,ZPSYMT,
     *                NITR,RES,PE,
     *                IPART,NDOM,MBPDOM,LDOM,NBPDOM,IPSLF,IPSND,
     *                WRK01,WRK02,WRK03,WRK04,WRK05,WRK06,
     *                FXYZ,RX,RY,MWRK,WRKN,
     *                IUT0,IERR)
          TIME_STOP(TM_BCGSXE)
      ELSE IF(ISOLP.EQ.2) THEN
          CALL RCMELM(MCOLOR,MCPART,NCOLOR,NCPART,LLOOP,
     *                ME,N,N1,NEX,NE,NP,NMAX,EPS,EPSRE,MRCM,NMAXB,
     *                NODE,CM,DNXYZ,DNXI,DNYI,DNZI,
     *                B,NPFIX,LPFIX,
     *                NPSYMT,LPSYMT,XPSYMT,YPSYMT,ZPSYMT,
     *                NITR,RES,PE,
     *                IPART,NDOM,MBPDOM,LDOM,NBPDOM,IPSLF,IPSND,
     *                FXYZ,WRK01,WRK02,WRK03,WRK04,
     *                WRK05,WRK06,WRK07,WRK08,WRK09,PRCM,APRCM,
     *                RX,RY,MWRK,WRKN,
     *                IUT0,IERR)
      ELSE
          IERR=1
      ENDIF
C
      IF(IERR.NE.0) THEN
          WRITE(IUT0,*) ERMSGC
          RETURN
      ENDIF
C
      CALL NODLEX(NODE,ME,NE,NP,N1,NEX,SN,
     *            IPART,LDOM,NBPDOM,NDOM,IPSLF,IPSND,MBPDOM,
     *            PE,PN,CM,IUT0,IERR,RX,RY,MAXBUF)
C  
C
      RETURN
      END
