;; Patient Verification Contract
;; Securely manages patient identities

;; Map to store patient identities (hash-based for privacy)
(define-map patients (buff 32)
  {
    registered-by: principal,
    active: bool
  }
)

;; Map to track facility access to patient data
(define-map facility-patient-access { facility: principal, patient-hash: (buff 32) } bool)

;; Register a patient
(define-public (register-patient (patient-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? patients patient-hash)) (err u1))
    (ok (map-set patients patient-hash
      {
        registered-by: tx-sender,
        active: true
      }
    ))
  )
)

;; Grant access to a facility for a patient
(define-public (grant-facility-access (facility principal) (patient-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? patients patient-hash)) (err u1))
    (ok (map-set facility-patient-access { facility: facility, patient-hash: patient-hash } true))
  )
)

;; Revoke access from a facility
(define-public (revoke-facility-access (facility principal) (patient-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? patients patient-hash)) (err u1))
    (ok (map-set facility-patient-access { facility: facility, patient-hash: patient-hash } false))
  )
)

;; Check if a facility has access to a patient
(define-read-only (has-access (facility principal) (patient-hash (buff 32)))
  (default-to false
    (map-get? facility-patient-access { facility: facility, patient-hash: patient-hash })
  )
)

;; Check if a patient exists
(define-read-only (patient-exists (patient-hash (buff 32)))
  (is-some (map-get? patients patient-hash))
)

;; Deactivate a patient record
(define-public (deactivate-patient (patient-hash (buff 32)))
  (let ((patient-data (map-get? patients patient-hash)))
    (begin
      (asserts! (is-some patient-data) (err u1))
      (asserts! (is-eq tx-sender (get registered-by (unwrap-panic patient-data))) (err u2))
      (ok (map-set patients patient-hash
        (merge (unwrap-panic patient-data) { active: false })
      ))
    )
  )
)
