;; Medical Record Transfer Contract
;; Handles secure exchange of information

;; Map to store medical record transfers
(define-map record-transfers uint
  {
    patient-hash: (buff 32),
    source-facility: principal,
    destination-facility: principal,
    record-hash: (buff 32),
    status: (string-ascii 20)
  }
)

;; Counter for transfer IDs
(define-data-var transfer-id-counter uint u0)

;; Initiate a medical record transfer
(define-public (initiate-transfer
                (patient-hash (buff 32))
                (destination-facility principal)
                (record-hash (buff 32)))
  (let ((current-id (var-get transfer-id-counter)))
    (begin
      (var-set transfer-id-counter (+ current-id u1))
      (ok (map-set record-transfers current-id
        {
          patient-hash: patient-hash,
          source-facility: tx-sender,
          destination-facility: destination-facility,
          record-hash: record-hash,
          status: "initiated"
        }
      ))
    )
  )
)

;; Accept a medical record transfer
(define-public (accept-transfer (transfer-id uint))
  (let ((transfer-data (map-get? record-transfers transfer-id)))
    (begin
      (asserts! (is-some transfer-data) (err u1))
      (asserts! (is-eq tx-sender (get destination-facility (unwrap-panic transfer-data))) (err u2))
      (asserts! (is-eq (get status (unwrap-panic transfer-data)) "initiated") (err u3))
      (ok (map-set record-transfers transfer-id
        (merge (unwrap-panic transfer-data) { status: "accepted" })
      ))
    )
  )
)

;; Reject a medical record transfer
(define-public (reject-transfer (transfer-id uint))
  (let ((transfer-data (map-get? record-transfers transfer-id)))
    (begin
      (asserts! (is-some transfer-data) (err u1))
      (asserts! (is-eq tx-sender (get destination-facility (unwrap-panic transfer-data))) (err u2))
      (asserts! (is-eq (get status (unwrap-panic transfer-data)) "initiated") (err u3))
      (ok (map-set record-transfers transfer-id
        (merge (unwrap-panic transfer-data) { status: "rejected" })
      ))
    )
  )
)

;; Get transfer details
(define-read-only (get-transfer (transfer-id uint))
  (map-get? record-transfers transfer-id)
)

;; Verify if a record transfer exists and is accepted
(define-read-only (is-transfer-valid (transfer-id uint))
  (let ((transfer-data (map-get? record-transfers transfer-id)))
    (and
      (is-some transfer-data)
      (is-eq (get status (unwrap-panic transfer-data)) "accepted")
    )
  )
)
