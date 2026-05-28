import Foundation
import SwiftData

enum TransactionService {
    
    // MARK: - Создание
    
    static func create(
        amount: Decimal,
        kind: TransactionKind,
        date: Date,
        card: Card,
        category: Category? = nil,
        note: String? = nil,
        context: ModelContext
    ) {
        let transaction = Transaction(
            amount: amount,
            date: date,
            kind: kind,
            note: note,
            card: card,
            category: category
        )
        context.insert(transaction)
        
        applyToBalance(amount: amount, kind: kind, card: card)
        try? context.save()
    }
    
    static func createPayment(
        amount: Decimal,
        date: Date,
        fromDebit: Card,
        toCredit: Card,
        note: String? = nil,
        context: ModelContext
    ) {
        let outgoing = Transaction(
            amount: amount,
            date: date,
            kind: .transferOut,
            note: note ?? "Погашение \(toCredit.name)",
            card: fromDebit,
            category: nil
        )
        
        let incoming = Transaction(
            amount: amount,
            date: date,
            kind: .payment,
            note: note ?? "С \(fromDebit.name)",
            card: toCredit,
            category: nil
        )
        
        outgoing.linkedTransaction = incoming
        incoming.linkedTransaction = outgoing
        
        context.insert(outgoing)
        context.insert(incoming)
        
        fromDebit.balance -= amount
        toCredit.currentDebt -= amount
        
        PaymentDistributor.applyPayment(
            amount: amount,
            toCard: toCredit,
            context: context
        )
        
        try? context.save()
    }
    
    // MARK: - Отмена (soft delete)
    
    static func cancel(_ transaction: Transaction, context: ModelContext) {
        guard !transaction.isCancelled else { return }
        
        if let card = transaction.card {
            revertFromBalance(
                amount: transaction.amount,
                kind: transaction.kind,
                card: card
            )
            
            if transaction.kind == .payment && card.type == .credit {
                PaymentDistributor.revertPayment(
                    amount: transaction.amount,
                    fromCard: card,
                    context: context
                )
            }
        }
        transaction.isCancelled = true
        transaction.cancelledAt = Date()
        
        if let linked = transaction.linkedTransaction, !linked.isCancelled {
            if let linkedCard = linked.card {
                revertFromBalance(
                    amount: linked.amount,
                    kind: linked.kind,
                    card: linkedCard
                )
                
                if linked.kind == .payment && linkedCard.type == .credit {
                    PaymentDistributor.revertPayment(
                        amount: linked.amount,
                        fromCard: linkedCard,
                        context: context
                    )
                }
            }
            linked.isCancelled = true
            linked.cancelledAt = Date()
        }
        
        try? context.save()
    }
    
    static func restore(_ transaction: Transaction, context: ModelContext) {
        guard transaction.isCancelled else { return }
        
        if let card = transaction.card {
            applyToBalance(
                amount: transaction.amount,
                kind: transaction.kind,
                card: card
            )
            
            if transaction.kind == .payment && card.type == .credit {
                PaymentDistributor.applyPayment(
                    amount: transaction.amount,
                    toCard: card,
                    context: context
                )
            }
        }
        transaction.isCancelled = false
        transaction.cancelledAt = nil
        
        if let linked = transaction.linkedTransaction, linked.isCancelled {
            if let linkedCard = linked.card {
                applyToBalance(
                    amount: linked.amount,
                    kind: linked.kind,
                    card: linkedCard
                )
                
                if linked.kind == .payment && linkedCard.type == .credit {
                    PaymentDistributor.applyPayment(
                        amount: linked.amount,
                        toCard: linkedCard,
                        context: context
                    )
                }
            }
            linked.isCancelled = false
            linked.cancelledAt = nil
        }
        
        try? context.save()
    }
    
    // MARK: - Полное удаление
    
    static func deleteForever(_ transaction: Transaction, context: ModelContext) {
        if !transaction.isCancelled {
            if let card = transaction.card {
                revertFromBalance(
                    amount: transaction.amount,
                    kind: transaction.kind,
                    card: card
                )
                
                if transaction.kind == .payment && card.type == .credit {
                    PaymentDistributor.revertPayment(
                        amount: transaction.amount,
                        fromCard: card,
                        context: context
                    )
                }
            }
        }
        
        if let linked = transaction.linkedTransaction {
            if !linked.isCancelled, let linkedCard = linked.card {
                revertFromBalance(
                    amount: linked.amount,
                    kind: linked.kind,
                    card: linkedCard
                )
                
                if linked.kind == .payment && linkedCard.type == .credit {
                    PaymentDistributor.revertPayment(
                        amount: linked.amount,
                        fromCard: linkedCard,
                        context: context
                    )
                }
            }
            context.delete(linked)
        }
        
        context.delete(transaction)
        try? context.save()
    }
    
    // MARK: - Логика обновления баланса
    
    private static func applyToBalance(
        amount: Decimal,
        kind: TransactionKind,
        card: Card
    ) {
        switch kind {
        case .expense:
            if card.type == .debit {
                card.balance -= amount
            } else {
                card.currentDebt += amount
            }
        case .income:
            if card.type == .debit {
                card.balance += amount
            }
        case .payment:
            if card.type == .debit {
                card.balance -= amount
            } else {
                card.currentDebt -= amount
            }
        case .transferOut:
            if card.type == .debit {
                card.balance -= amount
            }
        case .transferIn:
            if card.type == .debit {
                card.balance += amount
            }
        }
    }
    
    private static func revertFromBalance(
        amount: Decimal,
        kind: TransactionKind,
        card: Card
    ) {
        switch kind {
        case .expense:
            if card.type == .debit {
                card.balance += amount
            } else {
                card.currentDebt -= amount
            }
        case .income:
            if card.type == .debit {
                card.balance -= amount
            }
        case .payment:
            if card.type == .debit {
                card.balance += amount
            } else {
                card.currentDebt += amount
            }
        case .transferOut:
            if card.type == .debit {
                card.balance += amount
            }
        case .transferIn:
            if card.type == .debit {
                card.balance -= amount
            }
        }
    }
}
