(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MEMBER-EXISTS (err u101))
(define-constant ERR-NOT-MEMBER (err u102))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u103))
(define-constant ERR-VOTING-ENDED (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-INSUFFICIENT-BALANCE (err u106))
(define-constant ERR-BILL-NOT-FOUND (err u107))
(define-constant ERR-BILL-ALREADY-PAID (err u108))
(define-constant ERR-INVALID-AMOUNT (err u109))

(define-data-var contract-owner principal tx-sender)
(define-data-var next-proposal-id uint u1)
(define-data-var next-bill-id uint u1)
(define-data-var house-balance uint u0)
(define-data-var monthly-rent uint u0)

(define-map members principal 
    {
        active: bool,
        join-block: uint,
        deposit: uint,
        total-contributions: uint
    }
)

(define-map proposals uint
    {
        proposer: principal,
        title: (string-utf8 100),
        description: (string-utf8 500),
        proposal-type: (string-ascii 20),
        amount: uint,
        votes-for: uint,
        votes-against: uint,
        voting-ends: uint,
        executed: bool,
        created-at: uint
    }
)

(define-map votes {proposal-id: uint, voter: principal} 
    {
        vote: bool,
        block-height: uint
    }
)

(define-map bills uint
    {
        title: (string-utf8 100),
        total-amount: uint,
        per-person-amount: uint,
        due-date: uint,
        created-by: principal,
        paid-count: uint,
        total-members: uint,
        active: bool
    }
)

(define-map bill-payments {bill-id: uint, member: principal}
    {
        paid: bool,
        amount: uint,
        paid-at: uint
    }
)

(define-map house-rules (string-ascii 50)
    {
        rule: (string-utf8 200),
        active: bool,
        created-at: uint
    }
)

(define-public (initialize-house (initial-rent uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set monthly-rent initial-rent)
        (ok true)
    )
)

(define-public (join-house (deposit-amount uint))
    (let
        (
            (member-data (default-to {active: false, join-block: u0, deposit: u0, total-contributions: u0} 
                                   (map-get? members tx-sender)))
        )
        (asserts! (not (get active member-data)) ERR-MEMBER-EXISTS)
        (asserts! (>= deposit-amount u1000000) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
        (map-set members tx-sender
            {
                active: true,
                join-block: stacks-block-height,
                deposit: deposit-amount,
                total-contributions: deposit-amount
            }
        )
        (var-set house-balance (+ (var-get house-balance) deposit-amount))
        (ok true)
    )
)

(define-public (leave-house)
    (let
        (
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (deposit (get deposit member-data))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (map-set members tx-sender
            {
                active: false,
                join-block: (get join-block member-data),
                deposit: u0,
                total-contributions: (get total-contributions member-data)
            }
        )
        (var-set house-balance (- (var-get house-balance) deposit))
        (try! (as-contract (stx-transfer? deposit tx-sender tx-sender)))
        (ok true)
    )
)

(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)) 
                              (proposal-type (string-ascii 20)) (amount uint))
    (let
        (
            (proposal-id (var-get next-proposal-id))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (map-set proposals proposal-id
            {
                proposer: tx-sender,
                title: title,
                description: description,
                proposal-type: proposal-type,
                amount: amount,
                votes-for: u0,
                votes-against: u0,
                voting-ends: (+ stacks-block-height u144),
                executed: false,
                created-at: stacks-block-height
            }
        )
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (existing-vote (map-get? votes {proposal-id: proposal-id, voter: tx-sender}))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (asserts! (<= stacks-block-height (get voting-ends proposal)) ERR-VOTING-ENDED)
        (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
        
        (map-set votes {proposal-id: proposal-id, voter: tx-sender}
            {
                vote: vote-for,
                block-height: stacks-block-height
            }
        )
        
        (if vote-for
            (map-set proposals proposal-id
                (merge proposal {votes-for: (+ (get votes-for proposal) u1)})
            )
            (map-set proposals proposal-id
                (merge proposal {votes-against: (+ (get votes-against proposal) u1)})
            )
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (asserts! (> stacks-block-height (get voting-ends proposal)) ERR-VOTING-ENDED)
        (asserts! (not (get executed proposal)) ERR-VOTING-ENDED)
        (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR-NOT-AUTHORIZED)
        
        (map-set proposals proposal-id
            (merge proposal {executed: true})
        )
        
        (if (is-eq (get proposal-type proposal) "expense")
            (begin
                (asserts! (>= (var-get house-balance) (get amount proposal)) ERR-INSUFFICIENT-BALANCE)
                (var-set house-balance (- (var-get house-balance) (get amount proposal)))
                (ok true)
            )
            (ok true)
        )
    )
)

(define-public (create-bill (title (string-utf8 100)) (total-amount uint) (due-blocks uint))
    (let
        (
            (bill-id (var-get next-bill-id))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (active-members (get-active-member-count))
            (per-person (/ total-amount active-members))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (asserts! (> total-amount u0) ERR-INVALID-AMOUNT)
        
        (map-set bills bill-id
            {
                title: title,
                total-amount: total-amount,
                per-person-amount: per-person,
                due-date: (+ stacks-block-height due-blocks),
                created-by: tx-sender,
                paid-count: u0,
                total-members: active-members,
                active: true
            }
        )
        (var-set next-bill-id (+ bill-id u1))
        (ok bill-id)
    )
)

(define-public (pay-bill (bill-id uint))
    (let
        (
            (bill (unwrap! (map-get? bills bill-id) ERR-BILL-NOT-FOUND))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (payment-data (default-to {paid: false, amount: u0, paid-at: u0} 
                                    (map-get? bill-payments {bill-id: bill-id, member: tx-sender})))
            (payment-amount (get per-person-amount bill))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (asserts! (get active bill) ERR-BILL-NOT-FOUND)
        (asserts! (not (get paid payment-data)) ERR-BILL-ALREADY-PAID)
        
        (try! (stx-transfer? payment-amount tx-sender (as-contract tx-sender)))
        
        (map-set bill-payments {bill-id: bill-id, member: tx-sender}
            {
                paid: true,
                amount: payment-amount,
                paid-at: stacks-block-height
            }
        )
        
        (map-set bills bill-id
            (merge bill {paid-count: (+ (get paid-count bill) u1)})
        )
        
        (var-set house-balance (+ (var-get house-balance) payment-amount))
        (ok true)
    )
)

(define-public (add-house-rule (rule-key (string-ascii 50)) (rule-text (string-utf8 200)))
    (let
        (
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (map-set house-rules rule-key
            {
                rule: rule-text,
                active: true,
                created-at: stacks-block-height
            }
        )
        (ok true)
    )
)

(define-public (contribute-to-house (amount uint))
    (let
        (
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
        )
        (asserts! (get active member-data) ERR-NOT-MEMBER)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set members tx-sender
            (merge member-data 
                   {total-contributions: (+ (get total-contributions member-data) amount)})
        )
        (var-set house-balance (+ (var-get house-balance) amount))
        (ok true)
    )
)

(define-read-only (get-member-info (member principal))
    (map-get? members member)
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-bill (bill-id uint))
    (map-get? bills bill-id)
)

(define-read-only (get-bill-payment (bill-id uint) (member principal))
    (map-get? bill-payments {bill-id: bill-id, member: member})
)

(define-read-only (get-house-rule (rule-key (string-ascii 50)))
    (map-get? house-rules rule-key)
)

(define-read-only (get-house-balance)
    (var-get house-balance)
)

(define-read-only (get-monthly-rent)
    (var-get monthly-rent)
)

(define-read-only (is-member (member principal))
    (match (map-get? members member)
        member-data (get active member-data)
        false
    )
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-private (get-active-member-count)
    (fold check-active-member (list tx-sender) u0)
)

(define-private (check-active-member (member principal) (count uint))
    (if (is-member member)
        (+ count u1)
        count
    )
)
