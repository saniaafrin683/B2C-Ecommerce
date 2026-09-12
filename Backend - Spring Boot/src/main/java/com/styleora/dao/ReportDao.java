package com.styleora.dao;

import com.styleora.model.ReportSummary;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Repository
public class ReportDao {

    private static final String REAL_ORDER_FILTER =
            "lower(coalesce(o.customer.email, o.customerEmail, '')) not like '%@styleora.test' " +
            "and lower(coalesce(o.customer.email, o.customerEmail, '')) <> 'customer@styleora.com'";
    private static final String REAL_REVIEW_FILTER =
            "lower(coalesce(r.customerEmail, '')) not like '%@styleora.test'";

    @PersistenceContext
    private EntityManager entityManager;

    private final OrderDao orderDao;
    private final ProductDao productDao;
    private final CustomerDao customerDao;

    public ReportDao(OrderDao orderDao, ProductDao productDao, CustomerDao customerDao) {
        this.orderDao = orderDao;
        this.productDao = productDao;
        this.customerDao = customerDao;
    }

    public ReportSummary getSummary(String range) {
        LocalDate startDate = getStartDate(range);
        ReportSummary summary = new ReportSummary();
        summary.setTotalOrders(orderDao.countOrders(startDate));
        summary.setTotalRevenue(orderDao.getTotalRevenue(startDate));
        summary.setTotalCustomers(customerDao.countCustomers(startDate));
        summary.setTotalProducts(productDao.countProducts());
        summary.setTotalPayments(getLongValue(
                "select count(p) from Payment p where (:startDate is null or p.paymentDate >= :startDate)",
                startDate
        ));
        summary.setPendingOrders(orderDao.countPendingOrders(startDate));
        summary.setPendingPayments(getLongValue(
                "select count(p) from Payment p where lower(coalesce(p.paymentStatus, '')) like '%pending%' and (:startDate is null or p.paymentDate >= :startDate)",
                startDate
        ));
        summary.setPendingReviews(getLongValue(
                "select count(r) from Review r where " + REAL_REVIEW_FILTER + " " +
                        "and lower(coalesce(r.reviewStatus, 'pending')) like '%pending%' " +
                        "and (:startDate is null or r.reviewDate >= :startDate)",
                startDate
        ));
        summary.setLowStockItems(productDao.countLowStockProducts());
        return summary;
    }

    public List<Map<String, Object>> getMonthlyRevenue(String range) {
        LocalDate startDate = getStartDate(range);
        List<Object[]> rows = createObjectArrayQueryWithOptionalDate(
                "select function('date_format', o.createdAt, '%Y-%m'), coalesce(sum(coalesce(o.totalAmount, 0)), 0) " +
                        "from Order o " +
                        "where o.createdAt is not null and " + REAL_ORDER_FILTER + " " +
                        "and (:startDate is null or o.createdAt >= :startDate) " +
                        "group by function('date_format', o.createdAt, '%Y-%m') " +
                        "order by function('date_format', o.createdAt, '%Y-%m')",
                startDate
        ).getResultList();

        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("month", row[0]);
            item.put("revenue", toDouble(row[1]));
            result.add(item);
        }
        return result;
    }

    public List<Map<String, Object>> getMonthlyOrders(String range) {
        LocalDate startDate = getStartDate(range);
        List<Object[]> rows = createObjectArrayQueryWithOptionalDate(
                "select function('date_format', o.createdAt, '%Y-%m'), count(o) " +
                        "from Order o " +
                        "where o.createdAt is not null and " + REAL_ORDER_FILTER + " " +
                        "and (:startDate is null or o.createdAt >= :startDate) " +
                        "group by function('date_format', o.createdAt, '%Y-%m') " +
                        "order by function('date_format', o.createdAt, '%Y-%m')",
                startDate
        ).getResultList();

        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("month", row[0]);
            item.put("ordersCount", toLong(row[1]));
            result.add(item);
        }
        return result;
    }

    public List<Map<String, Object>> getTopProducts(String range) {
        LocalDate startDate = getStartDate(range);
        List<Object[]> rows = createObjectArrayQueryWithOptionalDate(
                "select oi.productName, coalesce(sum(oi.quantity), 0), coalesce(sum(oi.lineTotal), 0) " +
                        "from OrderItem oi " +
                        "where oi.productName is not null and trim(oi.productName) <> '' and " +
                        "(:startDate is null or exists (select o.id from Order o where o.id = oi.orderId and " + REAL_ORDER_FILTER + " and o.createdAt >= :startDate)) " +
                        "and exists (select o.id from Order o where o.id = oi.orderId and " + REAL_ORDER_FILTER + ") " +
                        "group by oi.productName " +
                        "order by coalesce(sum(oi.quantity), 0) desc",
                startDate
        ).setMaxResults(5).getResultList();

        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("productName", row[0]);
            item.put("totalSold", toLong(row[1]));
            item.put("totalRevenue", toDouble(row[2]));
            result.add(item);
        }
        return result;
    }

    public List<Map<String, Object>> getTopCustomers(String range) {
        LocalDate startDate = getStartDate(range);
        return orderDao.getTopCustomers(startDate, 5);
    }

    public String exportCsv(String range) {
        ReportSummary summary = getSummary(range);
        List<Map<String, Object>> topProducts = getTopProducts(range);
        List<Map<String, Object>> topCustomers = getTopCustomers(range);
        StringBuilder csv = new StringBuilder();
        csv.append("Metric,Value\n");
        csv.append("Total Orders,").append(summary.getTotalOrders()).append('\n');
        csv.append("Total Revenue,").append(summary.getTotalRevenue()).append('\n');
        csv.append("Total Customers,").append(summary.getTotalCustomers()).append('\n');
        csv.append("Total Products,").append(summary.getTotalProducts()).append('\n');
        csv.append("Total Payments,").append(summary.getTotalPayments()).append('\n');
        csv.append("Pending Orders,").append(summary.getPendingOrders()).append('\n');
        csv.append("Pending Payments,").append(summary.getPendingPayments()).append('\n');
        csv.append("Pending Reviews,").append(summary.getPendingReviews()).append('\n');
        csv.append("Low Stock Items,").append(summary.getLowStockItems()).append("\n\n");
        csv.append("Top Products,Total Sold,Total Revenue\n");
        for (Map<String, Object> product : topProducts) {
            csv.append(escape(product.get("productName"))).append(',')
                    .append(product.get("totalSold")).append(',')
                    .append(product.get("totalRevenue")).append('\n');
        }
        csv.append("\nTop Customers,Total Orders,Total Spend\n");
        for (Map<String, Object> customer : topCustomers) {
            csv.append(escape(customer.get("customerName"))).append(',')
                    .append(customer.get("totalOrders")).append(',')
                    .append(customer.get("totalSpend")).append('\n');
        }
        return csv.toString();
    }

    private Long getLongValue(String jpql) {
        return toLong(entityManager.createQuery(jpql).getSingleResult());
    }

    private Long getLongValue(String jpql, LocalDate startDate) {
        return toLong(createScalarQueryWithOptionalDate(jpql, startDate).getSingleResult());
    }

    private jakarta.persistence.TypedQuery<Object[]> createObjectArrayQueryWithOptionalDate(String jpql, LocalDate startDate) {
        return entityManager.createQuery(jpql, Object[].class).setParameter("startDate", startDate);
    }

    private jakarta.persistence.Query createScalarQueryWithOptionalDate(String jpql, LocalDate startDate) {
        return entityManager.createQuery(jpql).setParameter("startDate", startDate);
    }

    private Long toLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }

    private Double toDouble(Object value) {
        return value == null ? 0D : ((Number) value).doubleValue();
    }

    private LocalDate getStartDate(String range) {
        if (range == null || range.trim().isEmpty()) {
            return null;
        }

        LocalDate today = LocalDate.now();
        return switch (range.toLowerCase()) {
            case "today" -> today;
            case "7d" -> today.minusDays(6);
            case "30d" -> today.minusDays(29);
            case "12m" -> today.minusMonths(11).withDayOfMonth(1);
            default -> null;
        };
    }

    private String escape(Object value) {
        String text = value == null ? "" : value.toString().replace("\"", "\"\"");
        return "\"" + text + "\"";
    }
}
