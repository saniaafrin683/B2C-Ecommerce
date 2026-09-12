package com.styleora.dao;

import com.styleora.dto.CurrentStockSummaryDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class InventoryDao {

    private static final String REAL_ORDER_FILTER =
            "lower(coalesce(o.customer.email, o.customerEmail, '')) not like '%@styleora.test' " +
            "and lower(coalesce(o.customer.email, o.customerEmail, '')) <> 'customer@styleora.com'";

    @PersistenceContext
    private EntityManager entityManager;

    public List<CurrentStockSummaryDto> getCurrentStockSummaries() {
        String jpql =
                "select new com.styleora.dto.CurrentStockSummaryDto(" +
                        "p.id, " +
                        "coalesce(p.name, ''), " +
                        "coalesce(p.category, ''), " +
                        "coalesce(p.stock, 0), " +
                        "coalesce((select sum(coalesce(oi.quantity, 0)) from OrderItem oi " +
                        "left join oi.order o " +
                        "where oi.product.id = p.id " +
                        "and o is not null " +
                        "and " + REAL_ORDER_FILTER + " " +
                        "and lower(coalesce(o.orderStatus, '')) not like '%cancel%'), 0), " +
                        "coalesce((select sum(coalesce(pi.quantity, 0)) from PurchaseItem pi " +
                        "join pi.purchase purchaseRecord " +
                        "where pi.product.id = p.id " +
                        "and (lower(coalesce(purchaseRecord.purchaseStatus, '')) = 'received' " +
                        "or lower(coalesce(purchaseRecord.purchaseStatus, '')) like 'complete%' " +
                        "or purchaseRecord.stockApplied = true)), 0)" +
                        ") " +
                        "from Product p " +
                        "order by lower(coalesce(p.name, '')) asc, p.id asc";

        TypedQuery<CurrentStockSummaryDto> query = entityManager.createQuery(jpql, CurrentStockSummaryDto.class);
        return query.getResultList();
    }
}
