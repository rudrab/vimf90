      PROGRAM LEGACY
      IMPLICIT NONE
      INTEGER I
      DO 10 I = 1, 10
         WRITE(*,*) I
   10 CONTINUE
      CALL SUB1
      END
C     column one comment
      SUBROUTINE SUB1
      WRITE(*,*) 1
      END
*     another comment style
      REAL FUNCTION SQUARE(X)
      REAL X
      SQUARE = X*X
      END
      INTEGER*4 FUNCTION CUBE(N)
      INTEGER N
      CUBE = N**3
      END
      SUBROUTINE NESTED
      INTEGER I, J
      DO 20 I = 1, 3
         DO 30 J = 1, 3
            WRITE(*,*) I, J
   30    CONTINUE
   20 CONTINUE
      DO I = 1, 5
         WRITE(*,*) I
      END DO
      END
      SUBROUTINE CONT(A,
     &                B)
      REAL A, B
      END
      BLOCK DATA INIT
      COMMON /BLK/ X
      DATA X /1.0/
      END
