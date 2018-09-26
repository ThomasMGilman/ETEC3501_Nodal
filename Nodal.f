C THIS PROGRAM PERFORMS AC NODAL ANALYSIS, COMPOSITE BRANCHES ARE USED.
      REAL OMEGA
      COMPLEX YN,Y,J,E
      COMMON YN(40,41),NFROM(200),NTO(200),TYPE(200),
     1VALUE(200),ICONT(200),Y(200),NNODE,NBR,NN,J(200),E(200)
C READ AND WRITE TITLE
1     READ(5,15)(VALUE(K),K=1,80)
      WRITE(6,16)(VALUE(K),K=1,80)
C READ AND WRITE NETWORK INFORMATION
      NNODE=0
      READ(5,6)NBR
      DO 2 K=1,NBR
      READ(5,7)I,NFROM(I),NTO(I),TYPE(I),VALUE(I),ICONT(I),J(I),E(I)
      NNODE=MAX0(NNODE,NFROM(I),NTO(I))
2     CONTINUE
      NN=NNODE+1
      READ(5,8)OMEGA
      WRITE(6,9)NNODE,NBR,OMEGA
      WRITE(6,14)
      DO 3 I=1,NBR
3     WRITE(6,10)I,NFROM(I),NTO(I),TYPE(I),VALUE(I),ICONT(I),J(I),E(I)
C FORMULATE NODAL EQUATIONS AND SOLVE
      CALL FORM(OMEGA)
      WRITE(6,13)
      DO 4  I=1,NNODE
      WRITE(6,18)I
4     WRITE(6,11)(YN(K,I),K=1,NNODE)
      WRITE(6,12)
      WRITE(6,11)(YN(K,NN),K=1,NNODE)
      CALL GAUSS(NNODE)
C PRINT RESULTS
      WRITE(6,17)
      DO  5  I=1,NNODE
5     WRITE(6,19) I,YN(I,NN)
      GO TO 1
C COLLECTION OF FORMAT STATEMENTS
6     FORMAT(I3)
7     FORMAT(3I3,A2,E10.3,I3,4E10.3)
8     FORMAT(E10.3)
9     FORMAT(////1X,'NO. OF NODES - 1=',I2/1X,'NUMBER OF BRANCHES=',I3 
     1/1X,'FREQUENCY OF OPERATION=',E10.3//)
10    FORMAT(1H0,3(I3,1X),A2,1X,E10.3,1X,I3,1X,2(1E10.3,2X,1E10.3,1HJ,
     11X))
11    FORMAT(1H0,4X,'(',1E10.3,2X,1E10.3,1HJ ')')
12    FORMAT(1H0//' *** EQUIVALENT CURRENT SOURCE VECTOR***'//)
13    FORMAT(1H1, 2X,'***NODE ADMITTANCE MATRIX***'
     17X,'REAL PART',3X,'IMAG PART'/)
14    FORMAT(10X,'THE NETWORK IS DESCRIBED BY THE FOLLOWING BRANCHES'///
     13X,'I',1X,'FROM',1X,'TO',1X,'TYPE',2X,'VALUE',3X,'ICONT',
     17X,'J',20X,'E'/)
15    FORMAT(80A1)
16    FORMAT(1H1,80A1)
17    FORMAT (1X,//'***NODE VOLTAGES***'//)
18    FORMAT(1H0,'COLUMN ',I2)
19    FORMAT(1X,1HV,I2,3X,1E12.4,2X,1H+,1E12.4,1HJ)
      END

      SUBROUTINE FORM(OMEGA)
C THIS SUBROUTINE FORMULATES NODE ADMITTANCE MATRIX AND EQUIVALENT
C CURRENT SOURCE VECTOR BY DIRECT CONSTRUCTION.
      REAL OMEGA
      COMPLEX YN,Y,J,E
      COMMON YN(40,41),NFROM(200),NTO(200),TYPE(200),
     1VALUE(200),ICONT(200),Y(200),NNODE,NBR,NN,J(200),E(200)
      DATA R,L,C,G,VC/2H R,2H L,2H C,2H G,2HVC/
C ZERO OUT YN    MATRIX
      DO 20 I=1,NNODE
      DO 20 K=1,NN
20    YN(I,K)=CMPLX(0.,0.)
      DO 70 I=1,NBR
C DETERMINE ADMITTANCE TYPE AND VALUE 
      IF(ICONT(I).NE.0)GO TO 40
      ICONT(I)=I
      IF(TYPE(I).EQ. R)GO TO 30
      IF(TYPE(I).EQ.G)GO TO 22
      IF(TYPE(I).EQ.C )GO TO 25
      Y(I)=CMPLX(0.,-1./(OMEGA*VALUE(I)))
      GO TO 60
22    Y(I)=CMPLX(VALUE(I),0.)
      GO TO 60
25    Y(I)=CMPLX(0.,(OMEGA*VALUE(I)))
      GO TO 60
30    Y(I)=CMPLX(1/VALUE(I),0.)
      GO TO 60
40    IF(TYPE(I).EQ.VC)GO TO 55
C ERROR MESSAGE
      WRITE(6,53)
53    FORMAT(1H0,'ERROR IN ELEMENT TYPE')
      STOP
55    Y(I)=CMPLX(VALUE(I),0.)
60    ICON=ICONT(I)
C ADD CONTRIBUTIONS TO YN FROM ITH BRANCH
      IA=NFROM(I)
      IB=NTO(I)
      IC=NFROM(ICON)
      ID=NTO(ICON)
      IF(IA.NE.0.AND.IC.NE.0)YN(IA,IC)=YN(IA,IC)+Y(I)
      IF(IA.NE.0.AND.ID.NE.0)YN(IA,ID)=YN(IA,ID)-Y(I)
      IF(IB.NE.0.AND.IC.NE.0)YN(IB,IC)=YN(IB,IC)-Y(I)
      IF(IB.NE.0.AND.ID.NE.0)YN(IB,ID)=YN(IB,ID)+Y(I)
C ADD CONTRIBUTION TO JN FROM ITH BRANCH
      IF(IA.NE.0)YN(IA,NN)=YN(IA,NN)+J(I)-Y(I)*E(ICON)
      IF(IB.NE.0)YN(IB,NN)=YN(IB,NN)-J(I)+Y(I)*E(ICON)
70    CONTINUE 
      RETURN
      END

      SUBROUTINE GAUSS(N)
C THIS SUBROUTINE SOLVES N SIMULTANEOUS LINEAR EQUATIONS BY GAUSSIAN
C ELIMINATION METHOD.  ARRAY A IS THE AUGMENTED COEFFICIENT MATRIX,
C AT EXIT , THE (N+1)TH COLUMN OF A CONTAINS THE SOLUTIONS.
      COMPLEX A,PIVOT,B
      COMMON A(40,41)
      NP1=N+1
      EPS=1.E-30
C FORWARD ELIMINATION
C SEARCH FOR PIVOT ROW
      IC=1
      IR=1
    1 PIVOT=A(IR,IC)
      IPIVOT=IR
      DO 2 I=IR,N
      IF(CABS(A(I,IC)).LE.CABS(PIVOT)) GO TO 2
      PIVOT=A(I,IC)
      IPIVOT=I
    2 CONTINUE
C INTERCHANGE ROWS
      IF(CABS(PIVOT).LE.EPS) GO TO 8
      IF(IPIVOT.EQ.IR) GO TO 4
      DO 3 K=IC,NP1
      B=A(IPIVOT,K)
      A(IPIVOT,K)=A(IR,K)
      A(IR,K)=B
    3 CONTINUE
    4 CONTINUE
C NORMALIZE PIVOT
      DO 5 K=IC,NP1
    5 A(IR,K)=A(IR,K)/PIVOT
      IF(IR.EQ.N) GO TO 10
      IRP1=IR+1
C COLUMN REDUCTION
      DO 7 IP=IRP1,N
      B=A(IP,IC)
      IF(CABS(B).LE.EPS) GO TO 7
      DO 6 K=IC,NP1
      A(IP,K)=A(IP,K)-A(IR,K)*B
    6 CONTINUE
    7 CONTINUE
      IR=IR+1
      IC=IC+1
      GO TO 1
    8 WRITE(6,9)
    9 FORMAT(47H DETERMINANT EQUAL TO ZERO. NO UNIQUE SOLUTION.)
      STOP
C BACK SUBSTITUTION
   10 NM1=N-1
      DO 12 K=1,NM1
      NMK=N-K
      DO 11 J=1,K
      NP1MJ=N+1-J
   11 A(NMK,NP1)=A(NMK,NP1) -A(NMK,NP1MJ)*A(NP1MJ,NP1)
   12 CONTINUE
      RETURN
      END
