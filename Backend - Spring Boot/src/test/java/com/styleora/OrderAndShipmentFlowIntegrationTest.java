package com.styleora;

import com.styleora.dto.OrderItemPayload;
import com.styleora.dto.OrderRequest;
import com.styleora.dto.OrderStatusUpdateRequest;
import com.styleora.dao.OrderDao;
import com.styleora.model.Invoice;
import com.styleora.model.Order;
import com.styleora.model.Payment;
import com.styleora.model.Product;
import com.styleora.model.ReturnRequest;
import com.styleora.model.Review;
import com.styleora.model.Shipment;
import com.styleora.model.ShippingMethod;
import com.styleora.service.OrderService;
import com.styleora.service.ShipmentService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
class OrderAndShipmentFlowIntegrationTest {

    @Autowired
    private OrderService orderService;

    @Autowired
    private ShipmentService shipmentService;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Autowired
    private OrderDao orderDao;

    @Test
    void shipmentCreationUsesLatestCommittedOrderStatus() {
        Long productId = transactionTemplate.execute(status -> {
            Product product = new Product();
            product.setName("Integration Test Product");
            product.setCategory("Apparel");
            product.setPrice(BigDecimal.valueOf(1200));
            product.setDiscount(BigDecimal.ZERO);
            product.setStock(10);
            entityManager.persist(product);
            entityManager.flush();
            return product.getId();
        });

        Long shippingMethodId = transactionTemplate.execute(status -> {
            ShippingMethod shippingMethod = new ShippingMethod();
            shippingMethod.setName("Integration Courier");
            shippingMethod.setCourierName("Integration Courier");
            shippingMethod.setCost(80D);
            shippingMethod.setEstimatedDays(3);
            shippingMethod.setStatus("ACTIVE");
            entityManager.persist(shippingMethod);
            entityManager.flush();
            return shippingMethod.getId();
        });

        Long orderId = transactionTemplate.execute(status -> orderService.createOrder(buildOrderRequest("Pending", productId)).getId());
        assertNotNull(orderId);

        transactionTemplate.executeWithoutResult(status -> {
            OrderStatusUpdateRequest request = new OrderStatusUpdateRequest();
            request.setStatus("Shipped");
            orderService.updateOrderStatus(orderId, request);
        });

        Order persistedOrder = transactionTemplate.execute(status -> orderDao.getOrderByIdFresh(orderId));
        assertNotNull(persistedOrder);
        assertEquals("Shipped", persistedOrder.getOrderStatus());

        Shipment createdShipment = transactionTemplate.execute(status -> {
            Shipment shipment = new Shipment();
            shipment.setOrderId(orderId);
            shipment.setShippingMethodId(shippingMethodId);
            shipment.setCourierName("Integration Courier");
            shipment.setTrackingNumber("TRACK-INT-001");
            shipment.setShipmentStatus("Pending");
            return shipmentService.createShipment(shipment);
        });
        assertNotNull(createdShipment.getId());
        assertEquals(orderId, createdShipment.getOrderId());
    }

    @Test
    void nonCodDeliveredLifecycleSyncsOrderInvoiceAndPaymentStatuses() {
        Long productId = transactionTemplate.execute(status -> {
            Product product = new Product();
            product.setName("Lifecycle Test Product");
            product.setCategory("Apparel");
            product.setPrice(BigDecimal.valueOf(900));
            product.setDiscount(BigDecimal.ZERO);
            product.setStock(10);
            entityManager.persist(product);
            entityManager.flush();
            return product.getId();
        });

        Long orderId = transactionTemplate.execute(status -> {
            OrderRequest request = buildOrderRequest("Pending", productId);
            request.setOrderId("TEST-CARD-LIFECYCLE");
            request.setPaymentMethod("Card");
            request.setPaymentStatus("Pending");
            return orderService.createOrder(request).getId();
        });
        assertNotNull(orderId);

        transactionTemplate.executeWithoutResult(status -> {
            OrderStatusUpdateRequest request = new OrderStatusUpdateRequest();
            request.setStatus("Delivered");
            orderService.updateOrderStatus(orderId, request);
        });

        Order persistedOrder = transactionTemplate.execute(status -> orderDao.getOrderByIdFresh(orderId));
        assertNotNull(persistedOrder);
        assertEquals("Delivered", persistedOrder.getOrderStatus());
        assertEquals("Paid", persistedOrder.getPaymentStatus());

        Invoice latestInvoice = transactionTemplate.execute(status ->
                entityManager.createQuery("from Invoice i where i.orderId = :orderId order by i.id desc", Invoice.class)
                        .setParameter("orderId", orderId)
                        .setMaxResults(1)
                        .getSingleResult()
        );
        assertNotNull(latestInvoice);
        assertEquals("Paid", latestInvoice.getPaymentStatus());

        Payment latestPayment = transactionTemplate.execute(status ->
                entityManager.createQuery("from Payment p where p.orderId = :orderId order by p.id desc", Payment.class)
                        .setParameter("orderId", orderId)
                        .setMaxResults(1)
                        .getSingleResult()
        );
        assertNotNull(latestPayment);
        assertEquals("Paid", latestPayment.getPaymentStatus());
    }

    @Test
    void fullOrderUpdateSyncsNonCodPaymentLifecycleAcrossSnapshots() {
        Long productId = transactionTemplate.execute(status -> {
            Product product = new Product();
            product.setName("Admin Edit Lifecycle Product");
            product.setCategory("Apparel");
            product.setPrice(BigDecimal.valueOf(750));
            product.setDiscount(BigDecimal.ZERO);
            product.setStock(12);
            entityManager.persist(product);
            entityManager.flush();
            return product.getId();
        });

        Long orderId = transactionTemplate.execute(status -> {
            OrderRequest request = buildOrderRequest("Pending", productId);
            request.setOrderId("TEST-ADMIN-EDIT-LIFECYCLE");
            request.setPaymentMethod("bKash");
            request.setPaymentStatus("Pending");
            return orderService.createOrder(request).getId();
        });
        assertNotNull(orderId);

        transactionTemplate.executeWithoutResult(status -> {
            OrderRequest updateRequest = buildOrderRequest("Delivered", productId);
            updateRequest.setId(orderId);
            updateRequest.setOrderId("TEST-ADMIN-EDIT-LIFECYCLE");
            updateRequest.setPaymentMethod("bKash");
            updateRequest.setPaymentStatus("Pending");
            orderService.updateOrder(orderId, updateRequest);
        });

        Order persistedOrder = transactionTemplate.execute(status -> orderDao.getOrderByIdFresh(orderId));
        assertNotNull(persistedOrder);
        assertEquals("Delivered", persistedOrder.getOrderStatus());
        assertEquals("Paid", persistedOrder.getPaymentStatus());

        Invoice latestInvoice = transactionTemplate.execute(status ->
                entityManager.createQuery("from Invoice i where i.orderId = :orderId order by i.id desc", Invoice.class)
                        .setParameter("orderId", orderId)
                        .setMaxResults(1)
                        .getSingleResult()
        );
        assertNotNull(latestInvoice);
        assertEquals("Paid", latestInvoice.getPaymentStatus());

        Payment latestPayment = transactionTemplate.execute(status ->
                entityManager.createQuery("from Payment p where p.orderId = :orderId order by p.id desc", Payment.class)
                        .setParameter("orderId", orderId)
                        .setMaxResults(1)
                        .getSingleResult()
        );
        assertNotNull(latestPayment);
        assertEquals("Paid", latestPayment.getPaymentStatus());
    }

    @Test
    void deleteOrderRemovesDependentRecordsInSafeOrder() {
        Long productId = transactionTemplate.execute(status -> {
            Product product = new Product();
            product.setName("Delete Test Product");
            product.setCategory("Apparel");
            product.setPrice(BigDecimal.valueOf(650));
            product.setDiscount(BigDecimal.ZERO);
            product.setStock(10);
            entityManager.persist(product);
            entityManager.flush();
            return product.getId();
        });

        Long shippingMethodId = transactionTemplate.execute(status -> {
            ShippingMethod shippingMethod = new ShippingMethod();
            shippingMethod.setName("Delete Test Courier");
            shippingMethod.setCourierName("Delete Test Courier");
            shippingMethod.setCost(70D);
            shippingMethod.setEstimatedDays(2);
            shippingMethod.setStatus("ACTIVE");
            entityManager.persist(shippingMethod);
            entityManager.flush();
            return shippingMethod.getId();
        });

        Long orderId = transactionTemplate.execute(status -> {
            OrderRequest request = buildOrderRequest("Delivered", productId);
            request.setOrderId("TEST-DELETE-ORDER");
            return orderService.createOrder(request).getId();
        });
        assertNotNull(orderId);

        transactionTemplate.executeWithoutResult(status -> {
            Shipment shipment = new Shipment();
            shipment.setOrderId(orderId);
            shipment.setShippingMethodId(shippingMethodId);
            shipment.setCourierName("Delete Test Courier");
            shipment.setTrackingNumber("TRACK-DELETE-001");
            shipment.setShipmentStatus("Delivered");
            shipmentService.createShipment(shipment);

            ReturnRequest returnRequest = new ReturnRequest();
            returnRequest.setOrderId(orderId);
            returnRequest.setCustomerId(1L);
            returnRequest.setProductId(productId);
            returnRequest.setReason("Delete cleanup");
            returnRequest.setStatus("Pending");
            entityManager.persist(returnRequest);

            Review review = new Review();
            review.setReviewCode("REV-DELETE-001");
            review.setOrderId(orderId);
            review.setProductId(productId);
            review.setProductName("Delete Test Product");
            review.setCustomerId(1L);
            review.setCustomerName("Delete Tester");
            review.setCustomerEmail("delete@test.example");
            review.setRating(5);
            review.setReviewTitle("Cleanup");
            review.setReviewMessage("Cleanup review");
            review.setReviewStatus("Approved");
            entityManager.persist(review);
            entityManager.flush();
        });

        transactionTemplate.executeWithoutResult(status -> orderService.deleteOrder(orderId));

        Long remainingOrders = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(o) from Order o where o.id = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingShipments = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(s) from Shipment s where s.orderId = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingReturns = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(rr) from ReturnRequest rr where rr.orderId = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingPayments = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(p) from Payment p where p.orderId = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingInvoices = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(i) from Invoice i where i.orderId = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingItems = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(oi) from OrderItem oi where oi.order.id = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );
        Long remainingReviews = transactionTemplate.execute(status ->
                entityManager.createQuery("select count(r) from Review r where r.orderId = :orderId", Long.class)
                        .setParameter("orderId", orderId)
                        .getSingleResult()
        );

        assertEquals(0L, remainingOrders);
        assertEquals(0L, remainingShipments);
        assertEquals(0L, remainingReturns);
        assertEquals(0L, remainingPayments);
        assertEquals(0L, remainingInvoices);
        assertEquals(0L, remainingItems);
        assertEquals(0L, remainingReviews);
    }

    private OrderRequest buildOrderRequest(String orderStatus, Long productId) {
        OrderItemPayload item = new OrderItemPayload();
        item.setProductId(productId);
        item.setQuantity(1);

        OrderRequest request = new OrderRequest();
        request.setOrderId("TEST-ORDER-" + orderStatus);
        request.setCreatedAt(LocalDate.of(2026, 5, 18));
        request.setCustomerName("Flow Test Customer");
        request.setCustomerEmail("flow-test@example.com");
        request.setCustomerPhone("01700000000");
        request.setShippingAddress("Test shipping address");
        request.setBillingAddress("Test billing address");
        request.setPriority("Medium");
        request.setTax(0D);
        request.setDiscount(0D);
        request.setShippingCost(80D);
        request.setPaymentMethod("Cash on Delivery");
        request.setPaymentStatus("Pending");
        request.setDeliveryNumber("01700000000");
        request.setTrackingNumber("");
        request.setOrderStatus(orderStatus);
        request.setOrderItems(List.of(item));
        return request;
    }
}
