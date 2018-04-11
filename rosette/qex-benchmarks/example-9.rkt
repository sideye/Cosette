#lang rosette

(current-bitwidth 10)

(require "../cosette.rkt" "../util.rkt" "../denotation.rkt" 
         "../sql.rkt" "../evaluator.rkt" "../syntax.rkt" "../symmetry.rkt") 

(define scores-info (table-info "Scores" (list "StudentID" "CourseID" "Points")))
(define students-info (table-info "Students" (list "StudentNr" "StudentName")))
(define courses-info (table-info "Courses" (list "CourseNr" "CourseName")))

; SELECT Students.StudentName, Courses.CourseName, Scores.Points
; FROM Scores JOIN Students ON Scores.StudentID = Students.StudentNr
; JOIN Courses ON Courses.CourseNr = Scores.CourseID
; WHERE Scores.Points > 2 AND Students.StudentName LIKE "%bob%"
; AND Courses.CourseName LIKE "AI%"

(define (q tables)
  (SELECT (VALS "Students.StudentName" "Courses.CourseName" "Scores.Points")
   FROM   (JOIN (JOIN (NAMED (list-ref tables 0)) (NAMED (list-ref tables 1))) (NAMED (list-ref tables 2)))
   WHERE  (AND (AND (BINOP "Scores.StudentID" = "Students.StudentNr") 
                    (BINOP "Scores.CourseID" = "Courses.CourseNr"))
               (BINOP "Scores.Points" > 2))))

(define ros-instance (list q (list scores-info students-info courses-info))) 
(define table-info-list (last ros-instance))
(define table-size-list (make-list (length table-info-list) 3))
(define empty-tables (init-sym-tables table-info-list (build-list (length table-info-list) (lambda (x) 0))))
(define tables (init-sym-tables-from-func table-info-list table-size-list gen-qex-sym-schema))

(define qt (q empty-tables))

(define mconstr (big-step (init-constraint qt) 20))

;(define m-tables (init-sym-tables-from-func table-info-list table-size-list gen-sym-schema))
(define m-tables (init-sym-tables-from-func table-info-list table-size-list gen-qex-sym-schema))
(assert-sym-tables-mconstr m-tables (go-break-symmetry-single qt))

(define (test-now instance tables)
    (let* ([q ((list-ref instance 0) tables)])
      (cosette-check-output-prop q tables (list) prop-table-empty)))

(time (test-now ros-instance m-tables))
;(time (test-now ros-instance tables))