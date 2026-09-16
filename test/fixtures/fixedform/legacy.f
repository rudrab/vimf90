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
