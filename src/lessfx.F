C======================================================================C
C                                                                      C
C SOFTWARE NAME : FRONTFLOW_BLUE.8.1                                   C
C                                                                      C
C  SUB ROUTINE : LESSFX                                                C
C                                                                      C
C                                       WRITTEN BY Y.YAMADE            C
C                                                                      C
C                                                                      C
C CONTACT ADDRESS : IIS, THE UNIVERSITY OF TOKYO, CISS                 C
C                                                                      C
C THERMO-FLUID ANALYSIS SOLVERS FOR LARGE-SCALE-ASSEMBLY               C
C                                                                      C
C======================================================================C
      SUBROUTINE LESSFX(LOCAL,NODE,MB,NE,NP,N,N1,NS,NSP,N2D,
     *                  X,Y,Z,
     *                  NPSYMT,NPSYM2,LPSYMT,XPSYMT,YPSYMT,ZPSYMT,
     *                  NPCCL ,LPCCL1,LPCCL2,   
     *                  IPART ,MPINT ,NPINT ,LPINT1,LPINT2,LPINT3,
     *                  MDOM  ,NDOM  ,LDOM  ,NBPDOM,MBPDOM,IPSLF,IPSND,
     *                  LPBTOA,IUT0,IUT6,IERR,RX,RY,
     *                  MWRK,WRK1,WRK2,WRK3,WRK4,WRK5,WRK6,
     *                  IWRK,IWRK2)
      IMPLICIT NONE
      INTEGER*4 LOCAL,NODE,MB,NE,NP,N,N1,NS,NSP,N2D,
     *          NPSYMT,NPSYM2,LPSYMT,NPCCL ,LPCCL1,LPCCL2,   
     *          IPART ,MPINT ,NPINT ,LPINT1,LPINT2,LPINT3,
     *          MDOM  ,NDOM  ,LDOM  ,NBPDOM,MBPDOM,IPSLF,IPSND,
     *          LPBTOA,IUT0,IUT6,IERR,MWRK,IWRK,IWRK2
      REAL*8    X,Y,Z
      REAL*4    XPSYMT,YPSYMT,ZPSYMT,
     *          RX,RY,WRK1,WRK2,WRK3,WRK4,WRK5,WRK6
      DIMENSION LOCAL(NSP,NS,4),NODE(N1,NE),X(NP),Y(NP),Z(NP),
     *          LPSYMT(MB),
     *          XPSYMT(MB),YPSYMT(MB),ZPSYMT(MB),
     *          LPCCL1(NPCCL),LPCCL2(NPCCL) ,
     *          WRK1(NE),WRK2(NE),WRK3(NE),WRK4(NP),WRK5(NP),WRK6(NP),
     *          IWRK(MWRK),IWRK2(2,MWRK),RX(0:N,NE),RY(0:N,NE)
C
      DIMENSION LPINT1(MPINT),LPINT2(MPINT),LPINT3(MPINT),
     1          LDOM  (MDOM) ,NBPDOM(MDOM) ,
     2          IPSLF(MBPDOM,MDOM),IPSND(MBPDOM,MDOM)
C
      DIMENSION LPBTOA(NP)
C
      CHARACTER*60 ERMSGC
     & / ' ## SUBROUTINE LESSFX: FATAL      ERROR REPORT   ; RETURNED' /
C
      REAL*4    EPS
      DATA      EPS  /1.0E-10/
C
      INTEGER*4 MAXBUF,IERRA,IDIM,IDOM,IBP,IPCCL,IPINT1,IPINT2,MLST,
     *          IE,IS,IETYPE,I,NESYMT,IP,IESYMT,NNPS,IPSYMT
      REAL*8    ABSNOR
C
C
C         ( 3-D CALCULATION : SINGLE WORD & MULTI ELEMENT VERSION )
C                                           CODED BASED ON 'LESSRF'
C
C      DO THE FOLLOWING BOUNDARY CONDITION PREPARATIONS FOR 'LES3D'
C
C
C     (1) GENERATE NEIGHBORING DOMAIN LISTS FOR PARALLEL MODE EXECUTION
C
C     (2) EXTRACT SYMMETRIC BOUNDARY SURFACES, CALCULATE THEIR NORMALS,
C        AND ASSIGN SURFACE NORMALS TO SYMMETRIC NODES
C
C
C     ARGUMENT LISTINGS
C       (1) INPUT
C          LOCAL (I,IS); NODE NUMBER TABLE DEFINING ELEMENT SURFACES
C          NODE  (I,IE); NODE NUMBER TABLE BASED ON ELEMENT
C          NE          ; NUMBER OF TOTAL ELEMENTS
C          MP          ; MAX. NUMBER OF TOTAL NODES
C           NOTES ; MP DEFINES THE UPPER BOUND OF ARRAYS WRK1 AND WRK2
C          NP          ; NUMBER OF TOTAL    NODES
C          N           ; NUMBER OF NODES ASSIGNED TO ONE ELEMENT
C          N2D          ;NUMBER OF SURFACE ELEMENT DEFINING NODES ( =4 )
C          X       (IP); X-COORDINATE OF GLOBAL NODES
C          Y       (IP); Y-COORDINATE OF GLOBAL NODES
C          Z       (IP); Z-COORDINATE OF GLOBAL NODES
C          P       (IE); ELEMENT PRESSURE
C          GI       (I); LOCAL GZAI  COORDINATES OF ELEMENT'S NODES
C          EI       (I); LOCAL EATA  COORDINATES OF ELEMENT'S NODES
C          TI       (I); LOCAL THETA COORDINATES OF ELEMENT'S NODES
C
C          NPWALL      ; NUMBER      OF WALL BOUNDARY NODES
C          MPWALL      ; MAX. NUMBER OF WALL BOUNDARY NODES
C          LPWALL (IBP); WALL BOUNDARY NODES
C          MEPWL       ; MAX. NUMBER OF ADJACENT WALL SURFACE  ELEMENTS
C
C          NPSYMT      ; NUMBER OF SYMMETRIC BOUNDARY NODES
C          LPSYMT (IBP); SYMMETRIC BOUNDARY NODES
C
C          IPART       ; SUB-DOMAIN NUMBER THAT THIS TASK SHOULD TAKE/IS
C                       TAKING CARE OF. IPART BEING SET ZERO MEANS THAT
C                       THE PROGRAM SHOULD RUN/IS RUNNING IN SERIAL 
C                       MODE.
C          NPINT       ; NUMBER OF INTER-CONNECT BOUNDARY NODES
C          LPINT1 (IBP); INTER-CONNECT BOUNDARY NODES
C          LPINT2 (IBP); CORRESPONDING SUB-DOMAIN NUMBERS
C          LPINT3 (IBP); NODE NUMBER IN THE CORRESPONDING SUB-DOMAINS
C          MDOM        ; MAX. NUMBER OF THE NEIBERING SUB-DOMAINS
C          MBPDOM      ; THE MAXIMUM NUMBER OF THE INTER-CONNECT 
C                       BOUNDARY NODES FOR ONE NEIBERING SUB-DOMAIN
C
C          IUT0        ; FILE NUMBER TO WRITE  ERROR MESSAGE
C          IUT6        ; FILE NUMBER TO WRITE  CALCULATION SEQUENCE
C
C       (2) OUTPUT
C          NEWALL      ; NUMBER OF WALL BOUNDARY ELEMENTS
C          LEWALL(I,IBE); WALL BOUNDARY ELEMENT AND ITS SURFACE
C          XNWALL (IBE); X NORMAL OF WALL BOUNDARY SURFACE
C          YNWALL (IBE); Y NORMAL OF WALL BOUNDARY SURFACE
C          ZNWALL (IBE); Z NORMAL OF WALL BOUNDARY SURFACE
C          YP     (IBE); DISTANCE BETWEEN WALL AND ITS OPPOSITE SURFACES
C
C          XPSYMT (IBP); X-DIR COMPONENT OF SYMMETRIC NODE NORMAL VECTOR
C          YPSYMT (IBP); Y-DIR COMPONENT OF SYMMETRIC NODE NORMAL VECTOR
C          ZPSYMT (IBP); Z-DIR COMPONENT OF SYMMETRIC NODE NORMAL VECTOR
C
C          NDOM        ; NUMBER OF THE NERIBERING SUB-DOMAINS
C          LDOM  (IDOM); NEIBERING SUB-DOMAIN NUMBER
C          NBPDOM(IDOM); NUMBER OF INTER-CONNECT BOUNDARY NODES
C                       SHARING WITH THE IDOM'TH NEIBERING SUB-DOMAIN,
C                       LDOM(IDOM)
C          IPSLF (IBP,IDOM); INTER-CONNECT BOUNDARY NODE NUMBER IN THE
C                           CALLING TASK'S SUB-DOMAIN, FOR THE IDOM'TH
C                           NEIBERING SUB-DOMAIN, LDOM(IDOM)
C          IPSND (IBP,IDOM); INTER-CONNECT BOUNDARY NODE NUMBER IN THE
C                           SUB-DOMAIN THAT IS RECEIVING THE CALLING
C                           TASK'S RESIDUALS.
C
C          IERR        ; RETURN CODE WHOSE VALUE WILL BE EITHER
C                   0 --- INDICATING SUCCESSFUL TERMINATION
C                OR 1 --- INDICATING OCCURENCE OF SOME ERROR CONDITIONS
C
C       (4) WORK
C          WRK1  (IWRK); USED IN SURFEX, COSIN3, DDCOMX
C          WRK2  (IWRK); USED IN SURFEX, DDCOMX
C           NOTES ; GUARANTEE THE UPPER BOUND OF MP FOR WRK1 AND WRK2
C          WRK3  (IWRK); USED IN SURFEX
C          IWRK  (IWRK); USED INTERNALLY, AND IN SURFEX
C          IWRK2(2,IWRK);USED INTERNALLY
C          WRK4  (IWRK); USED INTERNALLY
C         -WRK6  (IWRK); USED INTERNALLY
C          RX    (I,IE); USED IN DDCOMX
C          RY    (I,IE); USED IN DDCOMX
C
C
      MAXBUF = NE*(N+1)
C
C
C
C  GENERATE NEIGHBORING DOMAIN LISTS FOR PARALLEL EXECUTION
C
C
C
      IF(IPART.GE.1) THEN
          WRITE(IUT6,*)
          WRITE(IUT6,*) ' LESSRF: GENERATING NEIGHBORING DOMAIN LIST'
C
          CALL DDCOM0(LPINT1,LPINT2,LPINT3,NPINT,MDOM,MBPDOM,
     *                LDOM,NBPDOM,NDOM,IPSLF,IPSND,IUT0,IERR)
          CALL ERRCHK(IUT6,IPART,1,IERR,IERRA)
          IF(IERRA.NE.0) THEN
              WRITE(IUT0,*)
              WRITE(IUT0,*) ERMSGC
              RETURN
          ENDIF
C
          IDIM = 0
          CALL DDCOMX(IPART,IDIM,LDOM,NBPDOM,NDOM,
     *                IPSLF,IPSND,MBPDOM,WRK4,WRK5,WRK6,NP,
     *                IUT0,IERR,RX,RY,MAXBUF)
          CALL ERRCHK(IUT6,IPART,1,IERR,IERRA)
          IF(IERRA.NE.0) THEN
              WRITE(IUT0,*)
              WRITE(IUT0,*) ERMSGC
              RETURN
          ENDIF
C
C         CONVERTE IPSND FROM BEFOR TO AFTER
          DO 10 IDOM=1,NDOM
             DO 15 IBP=1,NBPDOM(IDOM)
                IPSND(IBP,IDOM)=LPBTOA(IPSND(IBP,IDOM))
 15          CONTINUE
 10       CONTINUE
C
      ELSE IF(NPCCL.NE.0) THEN
          NPINT=NPCCL*2
          DO 50 IPCCL=1,NPCCL
              IPINT1= IPCCL
              IPINT2= IPCCL+NPCCL
              LPINT1(IPINT1) = LPCCL1(IPCCL)
              LPINT1(IPINT2) = LPCCL2(IPCCL)
              LPINT2(IPINT1) = IPART
              LPINT2(IPINT2) = IPART
              LPINT3(IPINT1) = LPCCL2(IPCCL)
              LPINT3(IPINT2) = LPCCL1(IPCCL)
   50     CONTINUE
          CALL DDCOM0(LPINT1,LPINT2,LPINT3,NPINT,MDOM,MBPDOM,
     *                LDOM,NBPDOM,NDOM,IPSLF,IPSND,IUT0,IERR)
          IF(IERR.NE.0) THEN
              WRITE(IUT0,*)
              WRITE(IUT0,*) ERMSGC
              RETURN
          ENDIF
      ENDIF
C
C
C  PREPARE FOR SYMMETRIC BOUNDARY CONDITIONS
C
C
C
C NOTES; SYMMETRIC SURFACE EXTRACTION AND THEIR NORMAL CALCULATION ARE
C       TEMPORARILY BE NEEDED FOR CALCULATING SYMMETRIC NODE NORMAL 
C       VECTORS.
C
C
C EXTRACT SYMMETRIC BOUNDARY SURFACES, CALCULATE THEIR NORMAL VECTORS
C AND ASSIGN SURFACE NORMAL VECTORS TO SYMMETRIC NODES
C
C
      WRITE(IUT6,*)
      WRITE(IUT6,*) ' LESSRF: EXTRACTING SYMMETRIC SURFACES,'
      WRITE(IUT6,*) '        CALCULATING SYMMETRIC SURFACE NORMALS AND'
      WRITE(IUT6,*) '        ASSIGNING SURFACE NORMAL TO SYMMETRIC NODE'
C
      MLST   = 2
      CALL SRFEXX(MWRK,MLST,NE,NP,N1,NS,NSP,N2D,
     *            LPSYMT,NPSYMT,LOCAL,NODE,
     *            IWRK2,NESYMT,MWRK,IWRK,IUT0,IERR)
      NPSYM2=NPSYMT
      CALL ERRCHK(IUT6,IPART,1,IERR,IERRA)
      IF(IERRA.NE.0) THEN
          WRITE(IUT0,*)
          WRITE(IUT0,*) ERMSGC
          RETURN
      ENDIF
C
      CALL CSIN3X(LOCAL,X,Y,Z,NODE,NE,NP,N1,NS,NSP,
     *            IWRK2,NESYMT,WRK1,WRK2,WRK3,WRK4)
C
      DO 400 IP = 1 , NP
          WRK4(IP) = 0.E0
          WRK5(IP) = 0.E0
          WRK6(IP) = 0.E0
  400 CONTINUE
C
      DO 420 IESYMT = 1 , NESYMT
          IE = IWRK2(1,IESYMT)
          IS = IWRK2(2,IESYMT)
          IF(     NODE(8,IE).GE.1) THEN ! HEX
             IETYPE = 4
          ELSE IF(NODE(6,IE).GE.1) THEN ! PRS  
             IETYPE = 3
          ELSE IF(NODE(5,IE).GE.1) THEN ! PYR
             IETYPE = 2
          ELSE                          ! TET
             IETYPE = 1
          END IF   
          IF(LOCAL(4,IS,IETYPE).GE.1) THEN ! QUADRILATERAL
             NNPS = 4
          ELSE                             ! TRIANGLE
             NNPS = 3
          ENDIF   
          DO 410 I = 1 , NNPS
              IP = NODE(LOCAL(I,IS,IETYPE),IE)
              WRK4(IP) = WRK4(IP)+WRK1(IESYMT)
              WRK5(IP) = WRK5(IP)+WRK2(IESYMT)
              WRK6(IP) = WRK6(IP)+WRK3(IESYMT)
  410     CONTINUE 
  420 CONTINUE
C
C SUPERIMPOSE NEIGHBORING DOMAIN NORMAL VECTORS
C
C  NOTES; THIS PART MUST BE CALLED FOR ALL THE DOMAINS WHETHER OR NOT
C        THEY HAVE A SYMMETRIC NODE. A DOMAIN WHICH HAS NO SYMMETRIC
C        NODE MUST ALSO SEND ITS ZERO (DUMMY) RESIDUALS TO ITS
C        NEIGHBORING DOMAINS OTHERWISE COMMUNICATION WILL BE LOCKED.
C        IF AT LEAST ONE OF THE NEIGHBORING DOMAIN POSSESSES A SYMMETRIC
C        SURFACE, A DOMAIN MAY ALSO BE ASSIGNED A NORMAL VECTOR TO ITS
C        SYMMETRIC NODE (WHICH IS ISOLATED IN THE DOMAIN) AFTER THE
C        COMMUNICATION.
C
      IDIM = 3
      CALL DDCOMX(IPART,IDIM,LDOM,NBPDOM,NDOM,
     *            IPSLF,IPSND,MBPDOM,WRK4,WRK5,WRK6,NP,
     *            IUT0,IERR,RX,RY,MAXBUF)
      CALL ERRCHK(IUT6,IPART,1,IERR,IERRA)
      IF(IERRA.NE.0) THEN
          WRITE(IUT0,*)
          WRITE(IUT0,*) ERMSGC
          RETURN
      ENDIF
C
      DO 430 IPSYMT = 1 , NPSYM2
          IP = LPSYMT(IPSYMT)
          ABSNOR = SQRT(WRK4(IP)**2+WRK5(IP)**2+WRK6(IP)**2+EPS)
          XPSYMT(IPSYMT) = WRK4(IP)/ABSNOR
          YPSYMT(IPSYMT) = WRK5(IP)/ABSNOR
          ZPSYMT(IPSYMT) = WRK6(IP)/ABSNOR
  430 CONTINUE
C
      WRITE(IUT6,*) ' DONE!'
      WRITE(IUT6,*) '   NESYMT=',NESYMT
C
      RETURN
      END
