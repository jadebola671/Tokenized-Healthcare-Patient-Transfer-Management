;; Facility Verification Contract
;; Validates legitimate healthcare providers

(define-data-var admin principal tx-sender)

;; Map to store verified facilities
(define-map verified-facilities principal
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    verified: bool
  }
)

;; Public function to register a facility
(define-public (register-facility (name (string-ascii 100)) (license-number (string-ascii 50)))
  (ok (map-set verified-facilities tx-sender
    {
      name: name,
      license-number: license-number,
      verified: false
    }
  ))
)

;; Admin function to verify a facility
(define-public (verify-facility (facility-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (is-some (map-get? verified-facilities facility-address)) (err u2))
    (ok (map-set verified-facilities facility-address
      (merge (unwrap-panic (map-get? verified-facilities facility-address))
        { verified: true }
      )
    ))
  )
)

;; Read-only function to check if a facility is verified
(define-read-only (is-verified-facility (facility-address principal))
  (match (map-get? verified-facilities facility-address)
    facility-data (get verified facility-data)
    false
  )
)

;; Read-only function to get facility details
(define-read-only (get-facility-details (facility-address principal))
  (map-get? verified-facilities facility-address)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (var-set admin new-admin))
  )
)
