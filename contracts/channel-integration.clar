;; Channel Integration Contract
;; Manages integration of various customer service channels

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-CHANNEL-EXISTS (err u201))
(define-constant ERR-CHANNEL-NOT-FOUND (err u202))
(define-constant ERR-INVALID-INPUT (err u203))
(define-constant ERR-CHANNEL-INACTIVE (err u204))

;; Data Variables
(define-data-var next-channel-id uint u1)
(define-data-var total-channels uint u0)

;; Data Maps
(define-map channels
  { channel-id: uint }
  {
    name: (string-ascii 30),
    channel-type: (string-ascii 20),
    endpoint: (string-ascii 100),
    manager-id: uint,
    active: bool,
    priority-level: uint,
    max-concurrent: uint,
    created-at: uint
  }
)

(define-map channel-by-name
  { name: (string-ascii 30) }
  { channel-id: uint }
)

(define-map channel-config
  { channel-id: uint }
  {
    auto-response: bool,
    escalation-threshold: uint,
    response-timeout: uint,
    quality-threshold: uint
  }
)

(define-map channel-metrics
  { channel-id: uint }
  {
    total-requests: uint,
    processed-requests: uint,
    average-response-time: uint,
    success-rate: uint
  }
)

;; Public Functions

;; Register a new channel
(define-public (register-channel
  (name (string-ascii 30))
  (channel-type (string-ascii 20))
  (endpoint (string-ascii 100))
  (manager-id uint)
  (priority-level uint)
  (max-concurrent uint))
  (let
    (
      (channel-id (var-get next-channel-id))
    )
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len channel-type) u0) ERR-INVALID-INPUT)
    (asserts! (<= priority-level u10) ERR-INVALID-INPUT)
    (asserts! (> max-concurrent u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? channel-by-name { name: name })) ERR-CHANNEL-EXISTS)

    (map-set channels
      { channel-id: channel-id }
      {
        name: name,
        channel-type: channel-type,
        endpoint: endpoint,
        manager-id: manager-id,
        active: true,
        priority-level: priority-level,
        max-concurrent: max-concurrent,
        created-at: block-height
      }
    )

    (map-set channel-by-name
      { name: name }
      { channel-id: channel-id }
    )

    (map-set channel-config
      { channel-id: channel-id }
      {
        auto-response: false,
        escalation-threshold: u5,
        response-timeout: u300,
        quality-threshold: u80
      }
    )

    (map-set channel-metrics
      { channel-id: channel-id }
      {
        total-requests: u0,
        processed-requests: u0,
        average-response-time: u0,
        success-rate: u100
      }
    )

    (var-set next-channel-id (+ channel-id u1))
    (var-set total-channels (+ (var-get total-channels) u1))

    (ok channel-id)
  )
)

;; Update channel configuration
(define-public (update-channel-config
  (channel-id uint)
  (auto-response bool)
  (escalation-threshold uint)
  (response-timeout uint)
  (quality-threshold uint))
  (let
    (
      (channel (unwrap! (map-get? channels { channel-id: channel-id }) ERR-CHANNEL-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= quality-threshold u100) ERR-INVALID-INPUT)
    (asserts! (> response-timeout u0) ERR-INVALID-INPUT)

    (map-set channel-config
      { channel-id: channel-id }
      {
        auto-response: auto-response,
        escalation-threshold: escalation-threshold,
        response-timeout: response-timeout,
        quality-threshold: quality-threshold
      }
    )

    (ok true)
  )
)

;; Activate/Deactivate channel
(define-public (set-channel-status (channel-id uint) (active bool))
  (let
    (
      (channel (unwrap! (map-get? channels { channel-id: channel-id }) ERR-CHANNEL-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set channels
      { channel-id: channel-id }
      (merge channel { active: active })
    )

    (ok true)
  )
)

;; Update channel metrics
(define-public (update-channel-metrics
  (channel-id uint)
  (requests uint)
  (processed uint)
  (response-time uint)
  (success-rate uint))
  (let
    (
      (current-metrics (unwrap! (map-get? channel-metrics { channel-id: channel-id }) ERR-CHANNEL-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= success-rate u100) ERR-INVALID-INPUT)

    (map-set channel-metrics
      { channel-id: channel-id }
      {
        total-requests: (+ (get total-requests current-metrics) requests),
        processed-requests: (+ (get processed-requests current-metrics) processed),
        average-response-time: response-time,
        success-rate: success-rate
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get channel details
(define-read-only (get-channel (channel-id uint))
  (map-get? channels { channel-id: channel-id })
)

;; Get channel by name
(define-read-only (get-channel-by-name (name (string-ascii 30)))
  (match (map-get? channel-by-name { name: name })
    channel-data (map-get? channels { channel-id: (get channel-id channel-data) })
    none
  )
)

;; Get channel configuration
(define-read-only (get-channel-config (channel-id uint))
  (map-get? channel-config { channel-id: channel-id })
)

;; Get channel metrics
(define-read-only (get-channel-metrics (channel-id uint))
  (map-get? channel-metrics { channel-id: channel-id })
)

;; Check if channel is active
(define-read-only (is-channel-active (channel-id uint))
  (match (map-get? channels { channel-id: channel-id })
    channel (get active channel)
    false
  )
)

;; Get total channels count
(define-read-only (get-total-channels)
  (var-get total-channels)
)
