;; Co-living DAO Contract
;; Comprehensive decentralized autonomous organization for co-living spaces
;; Includes membership management, proposal voting, treasury operations, and space governance

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MEMBER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-MEMBER (err u102))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u103))
(define-constant ERR-PROPOSAL-EXPIRED (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-INSUFFICIENT-BALANCE (err u106))
(define-constant ERR-SPACE-NOT-FOUND (err u107))
(define-constant ERR-SPACE-OCCUPIED (err u108))
(define-constant ERR-INVALID-AMOUNT (err u109))
(define-constant ERR-PROPOSAL-ACTIVE (err u110))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MEMBERSHIP-FEE u1000000) ;; 1 STX in microSTX
(define-constant PROPOSAL-DURATION u1440) ;; 1440 blocks (~10 days)
(define-constant QUORUM-THRESHOLD u50) ;; 50% participation required

;; Data Variables
(define-data-var next-proposal-id uint u1)
(define-data-var next-space-id uint u1)
(define-data-var treasury-balance uint u0)
(define-data-var total-members uint u0)

;; Data Maps
(define-map members principal {
    joined-at: uint,
    reputation: uint,
    is-active: bool,
    space-id: (optional uint)
})

(define-map proposals uint {
    title: (string-ascii 64),
    description: (string-ascii 256),
    proposer: principal,
    created-at: uint,
    expires-at: uint,
    yes-votes: uint,
    no-votes: uint,
    executed: bool,
    proposal-type: (string-ascii 32)
})

(define-map votes { proposal-id: uint, voter: principal } bool)

(define-map spaces uint {
    name: (string-ascii 32),
    capacity: uint,
    current-occupants: uint,
    monthly-fee: uint,
    amenities: (string-ascii 128),
    is-available: bool
})

(define-map space-occupants { space-id: uint, occupant: principal } uint)

;; Private Functions
(define-private (is-member (user principal))
    (match (map-get? members user)
        member (get is-active member)
        false
    )
)

(define-private (get-member-count)
    (var-get total-members)
)

(define-private (calculate-voting-power (user principal))
    (match (map-get? members user)
        member (+ u1 (/ (get reputation member) u100))
        u0
    )
)

;; Public Functions - Membership Management
(define-public (join-dao)
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? members caller)) ERR-ALREADY-MEMBER)
        (try! (stx-transfer? MEMBERSHIP-FEE caller (as-contract tx-sender)))
        (map-set members caller {
            joined-at: block-height,
            reputation: u100,
            is-active: true,
            space-id: none
        })
        (var-set treasury-balance (+ (var-get treasury-balance) MEMBERSHIP-FEE))
        (var-set total-members (+ (var-get total-members) u1))
        (ok true)
    )
)

(define-public (leave-dao)
    (let ((caller tx-sender))
        (asserts! (is-member caller) ERR-MEMBER-NOT-FOUND)
        (map-set members caller {
            joined-at: u0,
            reputation: u0,
            is-active: false,
            space-id: none
        })
        (var-set total-members (- (var-get total-members) u1))
        (ok true)
    )
)

(define-public (update-reputation (member principal) (new-reputation uint))
    (let ((caller tx-sender))
        (asserts! (is-eq caller CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-member member) ERR-MEMBER-NOT-FOUND)
        (match (map-get? members member)
            existing-member
            (begin
                (map-set members member (merge existing-member { reputation: new-reputation }))
                (ok true)
            )
            ERR-MEMBER-NOT-FOUND
        )
    )
)

;; Public Functions - Proposal System
(define-public (create-proposal (title (string-ascii 64)) (description (string-ascii 256)) (proposal-type (string-ascii 32)))
    (let (
        (caller tx-sender)
        (proposal-id (var-get next-proposal-id))
        (expires-at (+ block-height PROPOSAL-DURATION))
    )
        (asserts! (is-member caller) ERR-NOT-AUTHORIZED)
        (map-set proposals proposal-id {
            title: title,
            description: description,
            proposer: caller,
            created-at: block-height,
            expires-at: expires-at,
            yes-votes: u0,
            no-votes: u0,
            executed: false,
            proposal-type: proposal-type
        })
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool))
    (let (
        (caller tx-sender)
        (voting-power (calculate-voting-power caller))
    )
        (asserts! (is-member caller) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: caller })) ERR-ALREADY-VOTED)
        
        (match (map-get? proposals proposal-id)
            proposal
            (begin
                (asserts! (< block-height (get expires-at proposal)) ERR-PROPOSAL-EXPIRED)
                (map-set votes { proposal-id: proposal-id, voter: caller } vote)
                
                (if vote
                    (map-set proposals proposal-id 
                        (merge proposal { yes-votes: (+ (get yes-votes proposal) voting-power) }))
                    (map-set proposals proposal-id 
                        (merge proposal { no-votes: (+ (get no-votes proposal) voting-power) }))
                )
                (ok true)
            )
            ERR-PROPOSAL-NOT-FOUND
        )
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let ((caller tx-sender))
        (asserts! (is-member caller) ERR-NOT-AUTHORIZED)
        (match (map-get? proposals proposal-id)
            proposal
            (begin
                (asserts! (>= block-height (get expires-at proposal)) ERR-PROPOSAL-ACTIVE)
                (asserts! (not (get executed proposal)) ERR-PROPOSAL-EXPIRED)
                
                (let (
                    (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
                    (quorum-met (>= (* total-votes u100) (* (get-member-count) QUORUM-THRESHOLD)))
                    (proposal-passed (> (get yes-votes proposal) (get no-votes proposal)))
                )
                    (asserts! quorum-met ERR-NOT-AUTHORIZED)
                    
                    (if (and quorum-met proposal-passed)
                        (begin
                            (map-set proposals proposal-id (merge proposal { executed: true }))
                            (ok true)
                        )
                        (ok false)
                    )
                )
            )
            ERR-PROPOSAL-NOT-FOUND
        )
    )
)

;; Public Functions - Space Management
(define-public (create-space (name (string-ascii 32)) (capacity uint) (monthly-fee uint) (amenities (string-ascii 128)))
    (let (
        (caller tx-sender)
        (space-id (var-get next-space-id))
    )
        (asserts! (is-eq caller CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (> capacity u0) ERR-INVALID-AMOUNT)
        
        (map-set spaces space-id {
            name: name,
            capacity: capacity,
            current-occupants: u0,
            monthly-fee: monthly-fee,
            amenities: amenities,
            is-available: true
        })
        (var-set next-space-id (+ space-id u1))
        (ok space-id)
    )
)

(define-public (book-space (space-id uint))
    (let ((caller tx-sender))
        (asserts! (is-member caller) ERR-NOT-AUTHORIZED)
        
        (match (map-get? spaces space-id)
            space
            (begin
                (asserts! (get is-available space) ERR-SPACE-NOT-FOUND)
                (asserts! (< (get current-occupants space) (get capacity space)) ERR-SPACE-OCCUPIED)
                
                (try! (stx-transfer? (get monthly-fee space) caller (as-contract tx-sender)))
                
                (map-set spaces space-id 
                    (merge space { current-occupants: (+ (get current-occupants space) u1) }))
                (map-set space-occupants { space-id: space-id, occupant: caller } block-height)
                
                ;; Update member with space assignment
                (match (map-get? members caller)
                    member
                    (map-set members caller (merge member { space-id: (some space-id) }))
                    false
                )
                
                (var-set treasury-balance (+ (var-get treasury-balance) (get monthly-fee space)))
                (ok true)
            )
            ERR-SPACE-NOT-FOUND
        )
    )
)

(define-public (leave-space (space-id uint))
    (let ((caller tx-sender))
        (asserts! (is-member caller) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? space-occupants { space-id: space-id, occupant: caller })) ERR-NOT-AUTHORIZED)
        
        (match (map-get? spaces space-id)
            space
            (begin
                (map-set spaces space-id 
                    (merge space { current-occupants: (- (get current-occupants space) u1) }))
                (map-delete space-occupants { space-id: space-id, occupant: caller })
                
                ;; Update member to remove space assignment
                (match (map-get? members caller)
                    member
                    (map-set members caller (merge member { space-id: none }))
                    false
                )
                
                (ok true)
            )
            ERR-SPACE-NOT-FOUND
        )
    )
)

;; Treasury Functions
(define-public (withdraw-from-treasury (amount uint) (recipient principal))
    (let ((caller tx-sender))
        (asserts! (is-eq caller CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (<= amount (var-get treasury-balance)) ERR-INSUFFICIENT-BALANCE)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
        (var-set treasury-balance (- (var-get treasury-balance) amount))
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-member-info (member principal))
    (map-get? members member)
)

(define-read-only (get-proposal-info (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-space-info (space-id uint))
    (map-get? spaces space-id)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (get-total-members)
    (var-get total-members)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (is-space-occupant (space-id uint) (occupant principal))
    (is-some (map-get? space-occupants { space-id: space-id, occupant: occupant }))
)
