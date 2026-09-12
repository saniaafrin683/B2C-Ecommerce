package com.styleora.service;

import com.styleora.dao.CustomerDao;
import com.styleora.dao.ReviewDao;
import com.styleora.model.Coupon;
import com.styleora.model.Customer;
import com.styleora.model.Invoice;
import com.styleora.model.Order;
import com.styleora.model.Payment;
import com.styleora.model.Product;
import com.styleora.model.Purchase;
import com.styleora.model.PurchaseOrder;
import com.styleora.model.PurchaseReturn;
import com.styleora.model.Review;
import com.styleora.model.Shipment;
import com.styleora.model.ShippingMethod;
import com.styleora.model.Warehouse;
import com.styleora.util.CustomerStatusValidator;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(name = "styleora.seed.sample.enabled", havingValue = "true")
@org.springframework.core.annotation.Order(20)
@Transactional
public class AdminSampleDataSeedService implements CommandLineRunner {

    private static final Logger LOGGER = LoggerFactory.getLogger(AdminSampleDataSeedService.class);
    private static final List<String> DEMO_PAYMENT_TRANSACTION_IDS = Arrays.asList(
            "TXN-260401",
            "TXN-260402",
            "TXN-260403",
            "TXN-260404",
            "TXN-260405",
            "TXN-260406",
            "TXN-260407",
            "TXN-260408",
            "TXN-260409",
            "TXN-260410",
            "TXN-260411",
            "TXN-260412"
    );

    @PersistenceContext
    private EntityManager entityManager;

    private final CustomerDao customerDao;
    private final ReviewDao reviewDao;

    public AdminSampleDataSeedService(CustomerDao customerDao, ReviewDao reviewDao) {
        this.customerDao = customerDao;
        this.reviewDao = reviewDao;
    }

    @Override
    public void run(String... args) {
        cleanupSeededCustomers();
        seedWarehouses();
        seedShippingMethods();
        seedPurchases();
        seedPurchaseOrders();
        seedPurchaseReturns();
        seedOrders();
        seedInvoices();
        cleanupSeededPayments();
        seedCoupons();
        cleanupSeededReviews();
        cleanupSeededShipments();
        logTotals();
    }

    private void cleanupSeededCustomers() {
        int deleted = customerDao.deleteOrphanedSampleCustomers();
        LOGGER.info("Sample seed: sample customers inserted=0, orphaned demo customers removed={}, total={}",
                deleted,
                count("select count(c) from Customer c"));
    }

    private void cleanupSeededReviews() {
        int deleted = reviewDao.deleteSeededReviews();
        LOGGER.info("Sample seed: reviews inserted=0, demo reviews removed={}, total={}",
                deleted,
                count("select count(r) from Review r"));
    }

    private void seedCustomers() {
        int inserted = 0;

        for (Customer customer : List.of(
                createCustomer("CUST-1001", "Sania Akter", "sania.akter@styleora.test", "01710000001", "Female", LocalDate.of(1997, 3, 12), "Dhanmondi, Dhaka", "Dhaka", 6, 48500, "Active", LocalDate.of(2026, 4, 2)),
                createCustomer("CUST-1002", "Afrin Sultana", "afrin.sultana@styleora.test", "01710000002", "Female", LocalDate.of(1995, 8, 21), "Agrabad, Chattogram", "Chattogram", 3, 17400, "Active", LocalDate.of(2026, 4, 5)),
                createCustomer("CUST-1003", "Rahim Uddin", "rahim.uddin@styleora.test", "01710000003", "Male", LocalDate.of(1992, 1, 15), "Zindabazar, Sylhet", "Sylhet", 4, 22800, "Active", LocalDate.of(2026, 4, 9)),
                createCustomer("CUST-1004", "Maisha Rahman", "maisha.rahman@styleora.test", "01710000004", "Female", LocalDate.of(1999, 6, 18), "Khulshi, Chattogram", "Chattogram", 5, 31800, "Active", LocalDate.of(2026, 4, 12)),
                createCustomer("CUST-1005", "Karim Hasan", "karim.hasan@styleora.test", "01710000005", "Male", LocalDate.of(1990, 11, 30), "Kotwali, Rajshahi", "Rajshahi", 2, 9500, "Inactive", LocalDate.of(2026, 4, 18)),
                createCustomer("CUST-1006", "Nusrat Jahan", "nusrat.jahan@styleora.test", "01710000006", "Female", LocalDate.of(1998, 4, 27), "GEC Circle, Chattogram", "Chattogram", 7, 56200, "Active", LocalDate.of(2026, 4, 22)),
                createCustomer("CUST-1007", "Sakiba Noor", "sakiba.noor@styleora.test", "01710000007", "Female", LocalDate.of(1996, 9, 10), "Uttara, Dhaka", "Dhaka", 3, 15600, "Active", LocalDate.of(2026, 5, 1)),
                createCustomer("CUST-1008", "Swarna Das", "swarna.das@styleora.test", "01710000008", "Female", LocalDate.of(1994, 2, 14), "Shib Bari, Khulna", "Khulna", 8, 74200, "Active", LocalDate.of(2026, 5, 6)),
                createCustomer("CUST-1009", "Tanvir Ahmed", "tanvir.ahmed@styleora.test", "01710000009", "Male", LocalDate.of(1991, 12, 5), "Mirpur, Dhaka", "Dhaka", 5, 28400, "Active", LocalDate.of(2026, 5, 10)),
                createCustomer("CUST-1010", "Jannat Ara", "jannat.ara@styleora.test", "01710000010", "Female", LocalDate.of(2000, 7, 8), "Cantonment, Cumilla", "Cumilla", 4, 19600, "Active", LocalDate.of(2026, 5, 13)),
                createCustomer("CUST-1011", "Mahin Chowdhury", "mahin.chowdhury@styleora.test", "01710000011", "Male", LocalDate.of(1993, 10, 19), "Station Road, Rangpur", "Rangpur", 2, 8800, "Pending", LocalDate.of(2026, 5, 19)),
                createCustomer("CUST-1012", "Fariha Anjum", "fariha.anjum@styleora.test", "01710000012", "Female", LocalDate.of(1997, 5, 25), "Mymensingh Sadar, Mymensingh", "Mymensingh", 6, 42300, "Active", LocalDate.of(2026, 5, 24))
        )) {
            if (exists("select count(c) from Customer c where lower(c.customerCode) = lower(:value)", customer.getCustomerCode())) {
                continue;
            }

            try {
                customer.setStatus(CustomerStatusValidator.normalize(customer.getStatus(), "AdminSampleDataSeedService"));
                entityManager.persist(customer);
                inserted++;
            } catch (Exception ex) {
                LOGGER.warn("Sample seed skipped invalid customer code={}, email={}", customer.getCustomerCode(), customer.getEmail(), ex);
            }
        }

        entityManager.flush();
        LOGGER.info("Sample seed: customers inserted={}, total={}", inserted, count("select count(c) from Customer c"));
    }

    private void seedProducts() {
        int inserted = 0;

        for (Product product : List.of(
                createProduct("PRD-VEG-001", "Fresh Vegetable Basket", "Vegetable", "Deshi Harvest", "5 kg", "Unisex", 1450, 5, 2, 48),
                createProduct("PRD-BABY-001", "Organic Baby Food Pack", "Mother & Baby", "TinyCare", "900 g", "Unisex", 1250, 0, 2, 60),
                createProduct("PRD-FISH-001", "Premium River Fish Combo", "Fish & Meat", "Nodi Fresh", "3 kg", "Unisex", 2150, 3, 2, 35),
                createProduct("PRD-SPORT-001", "Adjustable Dumbbell Set", "Sports & Outdoors", "FitBangla", "20 kg", "Unisex", 7800, 7, 5, 18),
                createProduct("PRD-HOME-001", "Modern Wall Decor Set", "Home & Lifestyle", "GhorBari", "1 set", "Unisex", 3200, 8, 5, 22),
                createProduct("PRD-GROC-001", "Premium Rice & Spice Bundle", "Groceries", "Bazar Fresh", "10 kg", "Unisex", 1850, 4, 2, 52),
                createProduct("PRD-ACC-001", "Fast Charger Cable Kit", "Electronic Accessories", "Voltix", "350 g", "Unisex", 950, 0, 3, 76),
                createProduct("PRD-TV-001", "43 Inch Smart Television", "TV & Home Appliances", "VisionTech", "8 kg", "Unisex", 42500, 10, 8, 14),
                createProduct("PRD-DEV-001", "Smart Home Mini Camera", "Electronics Devices", "Nexa", "420 g", "Unisex", 5600, 6, 5, 27),
                createProduct("PRD-MEN-001", "Men Casual Sneaker", "Men & Boys Fashion", "Urban Step", "1 pair", "Male", 2950, 12, 5, 40),
                createProduct("PRD-LUX-001", "Classic Leather Watch Set", "Watches, Bags, Jewellery", "Timora", "1 set", "Unisex", 6800, 9, 5, 16),
                createProduct("PRD-BEAUTY-001", "Skin Care Essentials Box", "Health & Beauty", "GlowLab", "750 g", "Female", 2450, 5, 3, 44),
                createProduct("PRD-ELEC-001", "Android Tablet 10.1", "Electronics", "SkyTab", "650 g", "Unisex", 22800, 8, 8, 19),
                createProduct("PRD-WOMEN-001", "Women Fashion Handbag", "Women And Girls Fashion", "Noor Style", "1 piece", "Female", 3400, 11, 5, 33)
        )) {
            if (exists("select count(p) from Product p where lower(p.tagNumber) = lower(:value)", product.getTagNumber())) {
                continue;
            }

            entityManager.persist(product);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: products inserted={}, total={}", inserted, count("select count(p) from Product p"));
    }

    private void seedWarehouses() {
        int inserted = 0;

        for (Warehouse warehouse : List.of(
                createWarehouse("WH-001", "Dhaka Central Warehouse", "Tejgaon, Dhaka", "Sabbir Hossain", "01810000001", 1280, 96, 845000),
                createWarehouse("WH-002", "Chattogram Port Warehouse", "EPZ, Chattogram", "Jahid Hasan", "01810000002", 970, 68, 632000),
                createWarehouse("WH-003", "Sylhet Regional Hub", "Ambarkhana, Sylhet", "Mariam Begum", "01810000003", 640, 34, 312000),
                createWarehouse("WH-004", "Rajshahi Agro Depot", "Boalia, Rajshahi", "Rashed Karim", "01810000004", 780, 41, 418000),
                createWarehouse("WH-005", "Khulna Distribution Center", "Sonadanga, Khulna", "Tania Akter", "01810000005", 690, 28, 354000),
                createWarehouse("WH-006", "Rangpur North Hub", "Modern Mor, Rangpur", "Imran Kabir", "01810000006", 560, 19, 275000),
                createWarehouse("WH-007", "Cumilla Transit Hub", "Kotbari, Cumilla", "Nabila Islam", "01810000007", 510, 22, 241000),
                createWarehouse("WH-008", "Mymensingh Supply Point", "Ganginarpar, Mymensingh", "Shakil Ahmed", "01810000008", 475, 17, 223000),
                createWarehouse("WH-009", "Barishal Riverfront Depot", "Nathullabad, Barishal", "Farzana Yasmin", "01810000009", 430, 14, 198000),
                createWarehouse("WH-010", "Bogura Northern Stockhouse", "Satmatha, Bogura", "Mehedi Rana", "01810000010", 605, 26, 287000)
        )) {
            if (exists("select count(w) from Warehouse w where lower(w.warehouseId) = lower(:value)", warehouse.getWarehouseId())) {
                continue;
            }

            entityManager.persist(warehouse);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: warehouses inserted={}, total={}", inserted, count("select count(w) from Warehouse w"));
    }

    private void seedShippingMethods() {
        int inserted = 0;

        for (ShippingMethod shippingMethod : List.of(
                createShippingMethod("Inside Dhaka Express", "Fast same-city delivery for Dhaka orders", "Dhaka", "Pathao Courier", 80, 1000, 10, false, 1, 1, "Active"),
                createShippingMethod("Nationwide Standard", "Reliable delivery across Bangladesh", "Nationwide", "Sundarban Courier", 120, 500, 20, false, 3, 2, "Active"),
                createShippingMethod("Metro Next Day", "Next-day shipping for metro zones", "Dhaka, Chattogram, Sylhet", "RedX", 140, 1500, 12, false, 1, 3, "Active"),
                createShippingMethod("Free Shipping Campaign", "Free delivery for higher cart values", "Nationwide", "eCourier", 0, 3000, 15, true, 4, 4, "Active"),
                createShippingMethod("Heavy Goods Delivery", "Appliance and furniture delivery handling", "Nationwide", "Paperfly Logistics", 350, 5000, 60, false, 5, 5, "Active"),
                createShippingMethod("Store Pickup", "Customer pickup from assigned hub", "Selected Warehouses", "Styleora Pickup", 0, 0, 30, true, 0, 6, "Active")
        )) {
            if (exists("select count(s) from ShippingMethod s where lower(s.name) = lower(:value)", shippingMethod.getName())) {
                continue;
            }

            entityManager.persist(shippingMethod);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: shipping methods inserted={}, total={}", inserted, count("select count(s) from ShippingMethod s"));
    }

    private void seedPurchases() {
        int inserted = 0;

        for (Purchase purchase : List.of(
                createPurchase("PUR-001", "Sania", "sania@supplier.test", "01910000001", "Dhaka Fresh Market", purchaseItems("Fresh Vegetable Basket", "SKU-VEG-001", 3, 3800, 150, 250, 11500), "Completed", LocalDate.of(2026, 4, 16), 12500, "Cash", "Paid", 11850, 200, 150, 700, 12500, 0, "Completed cash purchase for grocery stock"),
                createPurchase("PUR-002", "Afrin", "afrin@supplier.test", "01910000002", "Chattogram Baby Supply", purchaseItems("Organic Baby Food Pack", "SKU-BABY-001", 1, 3600, 0, 100, 3700), "Completed", LocalDate.of(2026, 5, 20), 4000, "Credit Card", "Pending", 3700, 0, 100, 200, 0, 4000, "Card settlement pending"),
                createPurchase("PUR-003", "Rahim", "rahim@supplier.test", "01910000003", "Sylhet Protein Hub", purchaseItems("Premium River Fish Combo", "SKU-FISH-001", 5, 3450, 200, 300, 17350), "Pending", LocalDate.of(2026, 5, 22), 18750, "Bank Transfer", "Pending", 17350, 200, 300, 1300, 0, 18750, "Awaiting supplier dispatch"),
                createPurchase("PUR-004", "Maisha", "maisha@supplier.test", "01910000004", "Dhaka Sports Source", purchaseItems("Adjustable Dumbbell Set", "SKU-SPORT-001", 2, 3500, 0, 300, 7300), "Completed", LocalDate.of(2026, 5, 25), 7800, "Mobile Banking", "Paid", 7300, 0, 300, 200, 7800, 0, "Paid via bKash"),
                createPurchase("PUR-005", "Karim", "karim@supplier.test", "01910000005", "Khulna Daily Needs", purchaseItems("Premium Rice & Spice Bundle", "SKU-GROC-001", 4, 2100, 200, 200, 8400), "Cancelled", LocalDate.of(2026, 5, 28), 9500, "Cash", "Refunded", 8400, 200, 200, 1100, 0, 9500, "Supplier cancellation refunded in cash"),
                createPurchase("PUR-006", "Nusrat", "nusrat@supplier.test", "01910000006", "Electro World BD", purchaseItems("43 Inch Smart Television", "SKU-TV-001", 6, 3200, 300, 600, 19500), "Completed", LocalDate.of(2026, 6, 1), 21300, "Credit Card", "Paid", 19500, 300, 600, 1500, 21300, 0, "Bulk appliance restock"),
                createPurchase("PUR-007", "Sakiba", "sakiba@supplier.test", "01910000007", "Noor Fashion Supply", purchaseItems("Women Fashion Handbag", "SKU-WOMEN-001", 2, 2400, 100, 150, 4850), "Pending", LocalDate.of(2026, 6, 3), 5600, "Mobile Banking", "Pending", 4850, 100, 150, 700, 0, 5600, "Awaiting delivery confirmation"),
                createPurchase("PUR-008", "Swarna", "swarna@supplier.test", "01910000008", "Techline Importers", purchaseItems("Android Tablet 10.1", "SKU-ELEC-001", 8, 3600, 400, 800, 29200), "Completed", LocalDate.of(2026, 6, 5), 32000, "Bank Transfer", "Paid", 29200, 400, 800, 2400, 32000, 0, "High-volume electronics procurement"),
                createPurchase("PUR-009", "Tanvir", "tanvir@supplier.test", "01910000009", "Urban Step Wholesale", purchaseItems("Men Casual Sneaker", "SKU-MEN-001", 3, 3200, 150, 250, 9700), "In Progress", LocalDate.of(2026, 6, 7), 11200, "Cash", "Pending", 9700, 150, 250, 1400, 0, 11200, "Partially received"),
                createPurchase("PUR-010", "Jannat", "jannat@supplier.test", "01910000010", "GlowLab Distribution", purchaseItems("Skin Care Essentials Box", "SKU-BEAUTY-001", 5, 2700, 200, 300, 13600), "Completed", LocalDate.of(2026, 6, 9), 16400, "Credit Card", "Paid", 13600, 200, 300, 2500, 16400, 0, "Beauty line seasonal purchase")
        )) {
            if (exists("select count(p) from Purchase p where lower(p.purchaseId) = lower(:value)", purchase.getPurchaseId())) {
                continue;
            }

            entityManager.persist(purchase);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: purchases inserted={}, total={}", inserted, count("select count(p) from Purchase p"));
    }

    private void seedPurchaseOrders() {
        int inserted = 0;

        for (PurchaseOrder purchaseOrder : List.of(
                createPurchaseOrder("PO-001", "Mina Traders", "mina@po.test", "01610000001", "Karwan Bazar, Dhaka", LocalDate.of(2026, 4, 14), LocalDate.of(2026, 4, 19), "Completed", "Paid", "Cash", purchaseItems("Fresh Vegetable Basket", "SKU-VEG-001", 3, 3800, 150, 250, 11500), 11850, 200, 150, 700, 12500, 12500, 0, "Vegetable line replenishment"),
                createPurchaseOrder("PO-002", "Little Joy Supply", "littlejoy@po.test", "01610000002", "Halishahar, Chattogram", LocalDate.of(2026, 4, 20), LocalDate.of(2026, 4, 25), "Confirmed", "Pending", "Credit Card", purchaseItems("Organic Baby Food Pack", "SKU-BABY-001", 4, 1150, 0, 120, 4720), 4720, 0, 120, 160, 5000, 0, 5000, "Baby section restock"),
                createPurchaseOrder("PO-003", "River Catch BD", "rivercatch@po.test", "01610000003", "Beanibazar, Sylhet", LocalDate.of(2026, 5, 2), LocalDate.of(2026, 5, 7), "In Progress", "Pending", "Bank Transfer", purchaseItems("Premium River Fish Combo", "SKU-FISH-001", 5, 3450, 200, 300, 17350), 17350, 200, 300, 900, 18350, 0, 18350, "Fish combo replenishment"),
                createPurchaseOrder("PO-004", "FitBangla Supply", "fitbangla@po.test", "01610000004", "Uttara, Dhaka", LocalDate.of(2026, 5, 8), LocalDate.of(2026, 5, 14), "Completed", "Paid", "Mobile Banking", purchaseItems("Adjustable Dumbbell Set", "SKU-SPORT-001", 2, 3500, 0, 300, 7300), 7300, 0, 300, 200, 7800, 7800, 0, "Fitness inventory top-up"),
                createPurchaseOrder("PO-005", "HomeCraft Studio", "homecraft@po.test", "01610000005", "Khulna Sadar, Khulna", LocalDate.of(2026, 5, 12), LocalDate.of(2026, 5, 18), "Cancelled", "Refunded", "Cash", purchaseItems("Modern Wall Decor Set", "SKU-HOME-001", 4, 2100, 150, 150, 8400), 8400, 150, 150, 600, 9000, 0, 9000, "Supplier delay cancellation"),
                createPurchaseOrder("PO-006", "Bazar Fresh Agro", "bazarfresh@po.test", "01610000006", "Mymensingh Sadar, Mymensingh", LocalDate.of(2026, 5, 16), LocalDate.of(2026, 5, 21), "Completed", "Paid", "Bank Transfer", purchaseItems("Premium Rice & Spice Bundle", "SKU-GROC-001", 6, 1700, 200, 220, 10220), 10220, 200, 220, 760, 11000, 11000, 0, "Groceries stock fill"),
                createPurchaseOrder("PO-007", "Voltix Accessories", "voltix@po.test", "01610000007", "Motijheel, Dhaka", LocalDate.of(2026, 5, 20), LocalDate.of(2026, 5, 26), "Confirmed", "Pending", "Credit Card", purchaseItems("Fast Charger Cable Kit", "SKU-ACC-001", 10, 700, 0, 210, 7210), 7210, 0, 210, 490, 7700, 0, 7700, "Accessories bundle order"),
                createPurchaseOrder("PO-008", "VisionTech Imports", "visiontech@po.test", "01610000008", "Port Road, Chattogram", LocalDate.of(2026, 5, 25), LocalDate.of(2026, 5, 31), "Completed", "Paid", "Bank Transfer", purchaseItems("43 Inch Smart Television", "SKU-TV-001", 3, 12800, 500, 750, 38650), 38650, 500, 750, 1100, 40000, 40000, 0, "Television restocking batch"),
                createPurchaseOrder("PO-009", "Urban Step Wholesale", "urbanstep@po.test", "01610000009", "Mirpur, Dhaka", LocalDate.of(2026, 6, 2), LocalDate.of(2026, 6, 8), "In Progress", "Pending", "Cash", purchaseItems("Men Casual Sneaker", "SKU-MEN-001", 12, 2100, 300, 450, 25350), 25350, 300, 450, 1400, 27200, 0, 27200, "Seasonal footwear batch"),
                createPurchaseOrder("PO-010", "GlowLab Distribution", "glowlab@po.test", "01610000010", "Banani, Dhaka", LocalDate.of(2026, 6, 6), LocalDate.of(2026, 6, 12), "Completed", "Paid", "Credit Card", purchaseItems("Skin Care Essentials Box", "SKU-BEAUTY-001", 8, 2100, 240, 360, 16920), 16920, 240, 360, 1480, 18760, 18760, 0, "Beauty essentials restock")
        )) {
            if (exists("select count(p) from PurchaseOrder p where lower(p.purchaseOrderId) = lower(:value)", purchaseOrder.getPurchaseOrderId())) {
                continue;
            }

            entityManager.persist(purchaseOrder);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: purchase orders inserted={}, total={}", inserted, count("select count(p) from PurchaseOrder p"));
    }

    private void seedPurchaseReturns() {
        int inserted = 0;

        for (PurchaseReturn purchaseReturn : List.of(
                createPurchaseReturn("PR-001", "PO-001", "Mina Traders", "mina@po.test", "01610000001", LocalDate.of(2026, 4, 21), "Overripe vegetables in one carton", "Completed", "Refunded", "Cash", purchaseItems("Fresh Vegetable Basket", "SKU-VEG-001", 1, 2100, 0, 50, 2150), 2100, 50, 0, 2150, "Cash refund settled"),
                createPurchaseReturn("PR-002", "PO-002", "Little Joy Supply", "littlejoy@po.test", "01610000002", LocalDate.of(2026, 4, 28), "Damaged baby food packaging", "Pending", "Pending", "Credit Card", purchaseItems("Organic Baby Food Pack", "SKU-BABY-001", 1, 1150, 0, 30, 1180), 1150, 30, 0, 1180, "Awaiting supplier response"),
                createPurchaseReturn("PR-003", "PO-003", "River Catch BD", "rivercatch@po.test", "01610000003", LocalDate.of(2026, 5, 10), "Incorrect fish cut size delivered", "In Progress", "Pending", "Bank Transfer", purchaseItems("Premium River Fish Combo", "SKU-FISH-001", 1, 3450, 0, 90, 3540), 3450, 90, 0, 3540, "Replacement requested"),
                createPurchaseReturn("PR-004", "PO-004", "FitBangla Supply", "fitbangla@po.test", "01610000004", LocalDate.of(2026, 5, 18), "One dumbbell plate scratched", "Completed", "Refunded", "Mobile Banking", purchaseItems("Adjustable Dumbbell Set", "SKU-SPORT-001", 1, 3500, 100, 80, 3480), 3500, 80, 100, 3480, "Partial refund completed"),
                createPurchaseReturn("PR-005", "PO-005", "HomeCraft Studio", "homecraft@po.test", "01610000005", LocalDate.of(2026, 5, 22), "Order cancelled before dispatch", "Completed", "Refunded", "Cash", purchaseItems("Modern Wall Decor Set", "SKU-HOME-001", 2, 2100, 100, 60, 4160), 4200, 60, 100, 4160, "Cancellation settlement closed"),
                createPurchaseReturn("PR-006", "PO-006", "Bazar Fresh Agro", "bazarfresh@po.test", "01610000006", LocalDate.of(2026, 5, 27), "Broken spice packet found", "Pending", "Pending", "Bank Transfer", purchaseItems("Premium Rice & Spice Bundle", "SKU-GROC-001", 1, 1700, 0, 45, 1745), 1700, 45, 0, 1745, "Inspection underway"),
                createPurchaseReturn("PR-007", "PO-007", "Voltix Accessories", "voltix@po.test", "01610000007", LocalDate.of(2026, 6, 1), "Wrong cable connector type", "In Progress", "Pending", "Credit Card", purchaseItems("Fast Charger Cable Kit", "SKU-ACC-001", 2, 700, 0, 42, 1442), 1400, 42, 0, 1442, "Supplier reissue in process"),
                createPurchaseReturn("PR-008", "PO-008", "VisionTech Imports", "visiontech@po.test", "01610000008", LocalDate.of(2026, 6, 4), "Display panel issue on one unit", "Pending", "Pending", "Bank Transfer", purchaseItems("43 Inch Smart Television", "SKU-TV-001", 1, 12800, 200, 180, 12780), 12800, 180, 200, 12780, "Vendor assessment pending"),
                createPurchaseReturn("PR-009", "PO-009", "Urban Step Wholesale", "urbanstep@po.test", "01610000009", LocalDate.of(2026, 6, 10), "Size mismatch in shoe batch", "Completed", "Refunded", "Cash", purchaseItems("Men Casual Sneaker", "SKU-MEN-001", 2, 2100, 80, 50, 4170), 4200, 50, 80, 4170, "Issue resolved with refund"),
                createPurchaseReturn("PR-010", "PO-010", "GlowLab Distribution", "glowlab@po.test", "01610000010", LocalDate.of(2026, 6, 14), "Leakage in beauty serum pack", "Pending", "Pending", "Credit Card", purchaseItems("Skin Care Essentials Box", "SKU-BEAUTY-001", 1, 2100, 0, 55, 2155), 2100, 55, 0, 2155, "Credit memo under review")
        )) {
            if (exists("select count(p) from PurchaseReturn p where lower(p.returnId) = lower(:value)", purchaseReturn.getReturnId())) {
                continue;
            }

            entityManager.persist(purchaseReturn);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: purchase returns inserted={}, total={}", inserted, count("select count(p) from PurchaseReturn p"));
    }

    private void seedOrders() {
        if (count("select count(o) from Order o") > 0) {
            LOGGER.info("Sample seed: orders skipped because the orders table already contains data.");
            return;
        }

        int inserted = 0;

        for (Order order : List.of(
                createOrder("ORD-260401", LocalDate.of(2026, 4, 3), "Sania Akter", "sania.akter@styleora.test", "01710000001", "Dhanmondi, Dhaka", "Dhanmondi, Dhaka", "Low", 11200, 560, 400, 240, 11600, "Cash", "Paid", 3, "DLV-1001", "TRK-260401", "Delivered"),
                createOrder("ORD-260402", LocalDate.of(2026, 4, 8), "Afrin Sultana", "afrin.sultana@styleora.test", "01710000002", "Agrabad, Chattogram", "Agrabad, Chattogram", "Medium", 3800, 190, 0, 110, 4100, "Credit Card", "Pending", 1, "DLV-1002", "TRK-260402", "Confirmed"),
                createOrder("ORD-260403", LocalDate.of(2026, 4, 15), "Rahim Uddin", "rahim.uddin@styleora.test", "01710000003", "Zindabazar, Sylhet", "Zindabazar, Sylhet", "High", 17300, 865, 250, 335, 18250, "Bank Transfer", "Pending", 5, "DLV-1003", "TRK-260403", "In Progress"),
                createOrder("ORD-260404", LocalDate.of(2026, 4, 19), "Maisha Rahman", "maisha.rahman@styleora.test", "01710000004", "Khulshi, Chattogram", "Khulshi, Chattogram", "Low", 7300, 365, 0, 135, 7800, "Mobile Banking", "Paid", 2, "DLV-1004", "TRK-260404", "Delivered"),
                createOrder("ORD-260405", LocalDate.of(2026, 4, 24), "Karim Hasan", "karim.hasan@styleora.test", "01710000005", "Kotwali, Rajshahi", "Kotwali, Rajshahi", "High", 9100, 455, 150, 195, 9600, "Cash", "Refunded", 4, "DLV-1005", "TRK-260405", "Cancelled"),
                createOrder("ORD-260406", LocalDate.of(2026, 5, 2), "Nusrat Jahan", "nusrat.jahan@styleora.test", "01710000006", "GEC Circle, Chattogram", "GEC Circle, Chattogram", "Low", 20500, 1025, 200, 475, 21800, "Credit Card", "Paid", 6, "DLV-1006", "TRK-260406", "Shipped"),
                createOrder("ORD-260407", LocalDate.of(2026, 5, 7), "Sakiba Noor", "sakiba.noor@styleora.test", "01710000007", "Uttara, Dhaka", "Uttara, Dhaka", "Medium", 5400, 270, 100, 130, 5700, "Mobile Banking", "Pending", 2, "DLV-1007", "TRK-260407", "Pending Review"),
                createOrder("ORD-260408", LocalDate.of(2026, 5, 12), "Swarna Das", "swarna.das@styleora.test", "01710000008", "Shib Bari, Khulna", "Shib Bari, Khulna", "Low", 31200, 1560, 500, 540, 32800, "Bank Transfer", "Paid", 8, "DLV-1008", "TRK-260408", "Delivered"),
                createOrder("ORD-260409", LocalDate.of(2026, 5, 18), "Tanvir Ahmed", "tanvir.ahmed@styleora.test", "01710000009", "Mirpur, Dhaka", "Mirpur, Dhaka", "Medium", 10800, 540, 150, 210, 11400, "Cash", "Pending", 3, "DLV-1009", "TRK-260409", "In Progress"),
                createOrder("ORD-260410", LocalDate.of(2026, 5, 23), "Jannat Ara", "jannat.ara@styleora.test", "01710000010", "Cantonment, Cumilla", "Cantonment, Cumilla", "Low", 15600, 780, 200, 220, 16400, "Credit Card", "Paid", 5, "DLV-1010", "TRK-260410", "Confirmed"),
                createOrder("ORD-260411", LocalDate.of(2026, 5, 28), "Mahin Chowdhury", "mahin.chowdhury@styleora.test", "01710000011", "Station Road, Rangpur", "Station Road, Rangpur", "High", 8450, 422.5, 0, 127.5, 9000, "Bank Transfer", "Unpaid", 2, "DLV-1011", "TRK-260411", "Shipped"),
                createOrder("ORD-260412", LocalDate.of(2026, 6, 4), "Fariha Anjum", "fariha.anjum@styleora.test", "01710000012", "Mymensingh Sadar, Mymensingh", "Mymensingh Sadar, Mymensingh", "Low", 19800, 990, 250, 260, 20800, "Mobile Banking", "Paid", 4, "DLV-1012", "TRK-260412", "Delivered")
        )) {
            if (exists("select count(o) from Order o where lower(o.orderId) = lower(:value)", order.getOrderId())) {
                continue;
            }

            entityManager.persist(order);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: orders inserted={}, total={}", inserted, count("select count(o) from Order o"));
    }

    private void seedInvoices() {
        if (count("select count(i) from Invoice i") > 0) {
            LOGGER.info("Sample seed: invoices skipped because the invoices table already contains data.");
            return;
        }

        int inserted = 0;

        for (Invoice invoice : List.of(
                createInvoice("INV-260401", "ORD-260401", "Sania Akter", "sania.akter@styleora.test", "Dhanmondi, Dhaka", 11200, 560, 400, 240, 11600, "Paid", "Cash", LocalDate.of(2026, 4, 3), LocalDate.of(2026, 4, 10)),
                createInvoice("INV-260402", "ORD-260402", "Afrin Sultana", "afrin.sultana@styleora.test", "Agrabad, Chattogram", 3800, 190, 0, 110, 4100, "Pending", "Credit Card", LocalDate.of(2026, 4, 8), LocalDate.of(2026, 4, 15)),
                createInvoice("INV-260403", "ORD-260403", "Rahim Uddin", "rahim.uddin@styleora.test", "Zindabazar, Sylhet", 17300, 865, 250, 335, 18250, "Pending", "Bank Transfer", LocalDate.of(2026, 4, 15), LocalDate.of(2026, 4, 22)),
                createInvoice("INV-260404", "ORD-260404", "Maisha Rahman", "maisha.rahman@styleora.test", "Khulshi, Chattogram", 7300, 365, 0, 135, 7800, "Paid", "Mobile Banking", LocalDate.of(2026, 4, 19), LocalDate.of(2026, 4, 26)),
                createInvoice("INV-260405", "ORD-260405", "Karim Hasan", "karim.hasan@styleora.test", "Kotwali, Rajshahi", 9100, 455, 150, 195, 9600, "Refunded", "Cash", LocalDate.of(2026, 4, 24), LocalDate.of(2026, 5, 1)),
                createInvoice("INV-260406", "ORD-260406", "Nusrat Jahan", "nusrat.jahan@styleora.test", "GEC Circle, Chattogram", 20500, 1025, 200, 475, 21800, "Paid", "Credit Card", LocalDate.of(2026, 5, 2), LocalDate.of(2026, 5, 9)),
                createInvoice("INV-260407", "ORD-260407", "Sakiba Noor", "sakiba.noor@styleora.test", "Uttara, Dhaka", 5400, 270, 100, 130, 5700, "Pending", "Mobile Banking", LocalDate.of(2026, 5, 7), LocalDate.of(2026, 5, 14)),
                createInvoice("INV-260408", "ORD-260408", "Swarna Das", "swarna.das@styleora.test", "Shib Bari, Khulna", 31200, 1560, 500, 540, 32800, "Paid", "Bank Transfer", LocalDate.of(2026, 5, 12), LocalDate.of(2026, 5, 19)),
                createInvoice("INV-260409", "ORD-260409", "Tanvir Ahmed", "tanvir.ahmed@styleora.test", "Mirpur, Dhaka", 10800, 540, 150, 210, 11400, "Pending", "Cash", LocalDate.of(2026, 5, 18), LocalDate.of(2026, 5, 25)),
                createInvoice("INV-260410", "ORD-260410", "Jannat Ara", "jannat.ara@styleora.test", "Cantonment, Cumilla", 15600, 780, 200, 220, 16400, "Paid", "Credit Card", LocalDate.of(2026, 5, 23), LocalDate.of(2026, 5, 30)),
                createInvoice("INV-260411", "ORD-260411", "Mahin Chowdhury", "mahin.chowdhury@styleora.test", "Station Road, Rangpur", 8450, 422.5, 0, 127.5, 9000, "Pending", "Bank Transfer", LocalDate.of(2026, 5, 28), LocalDate.of(2026, 6, 4)),
                createInvoice("INV-260412", "ORD-260412", "Fariha Anjum", "fariha.anjum@styleora.test", "Mymensingh Sadar, Mymensingh", 19800, 990, 250, 260, 20800, "Paid", "Mobile Banking", LocalDate.of(2026, 6, 4), LocalDate.of(2026, 6, 11))
        )) {
            if (exists("select count(i) from Invoice i where lower(i.invoiceNumber) = lower(:value)", invoice.getInvoiceNumber())) {
                continue;
            }

            entityManager.persist(invoice);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: invoices inserted={}, total={}", inserted, count("select count(i) from Invoice i"));
    }

    private void cleanupSeededPayments() {
        int deleted = entityManager.createQuery("delete from Payment p where p.transactionId in :transactionIds")
                .setParameter("transactionIds", DEMO_PAYMENT_TRANSACTION_IDS)
                .executeUpdate();
        entityManager.flush();
        LOGGER.info("Sample seed: removed seeded demo payments count={}, remainingTotal={}", deleted, count("select count(p) from Payment p"));
    }

    private void seedCoupons() {
        if (count("select count(c) from Coupon c") > 0) {
            LOGGER.info("Sample seed: coupons skipped because the coupons table already contains data.");
            return;
        }

        int inserted = 0;

        for (Coupon coupon : List.of(
                createCoupon("NEWBDT100", "Flat", 100, LocalDate.of(2026, 4, 1), LocalDate.of(2026, 6, 30), 500, 72, 1000, "Active", "Flat BDT 100 off for new customers"),
                createCoupon("EID15", "Percentage", 15, LocalDate.of(2026, 4, 10), LocalDate.of(2026, 5, 20), 300, 188, 2000, "Expired", "Eid campaign percentage discount"),
                createCoupon("SUMMER200", "Flat", 200, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 6, 30), 250, 91, 3000, "Active", "Seasonal flat discount"),
                createCoupon("APP10", "Percentage", 10, LocalDate.of(2026, 4, 15), LocalDate.of(2026, 6, 15), 400, 133, 1500, "Active", "App checkout discount"),
                createCoupon("BEAUTY250", "Flat", 250, LocalDate.of(2026, 5, 5), LocalDate.of(2026, 6, 20), 150, 40, 3500, "Active", "Beauty category promo"),
                createCoupon("SPORT12", "Percentage", 12, LocalDate.of(2026, 5, 10), LocalDate.of(2026, 6, 18), 120, 28, 2500, "Active", "Sports campaign"),
                createCoupon("HOME150", "Flat", 150, LocalDate.of(2026, 4, 20), LocalDate.of(2026, 6, 5), 180, 64, 2200, "Active", "Home lifestyle sale"),
                createCoupon("FLASH50", "Flat", 50, LocalDate.of(2026, 5, 18), LocalDate.of(2026, 5, 25), 100, 100, 800, "Inactive", "Flash campaign finished"),
                createCoupon("MEGA20", "Percentage", 20, LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30), 90, 7, 5000, "Active", "High cart value offer"),
                createCoupon("FREESHIP", "Flat", 120, LocalDate.of(2026, 4, 5), LocalDate.of(2026, 6, 12), 350, 149, 1800, "Active", "Shipping cost offset coupon")
        )) {
            if (exists("select count(c) from Coupon c where lower(c.couponCode) = lower(:value)", coupon.getCouponCode())) {
                continue;
            }

            entityManager.persist(coupon);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: coupons inserted={}, total={}", inserted, count("select count(c) from Coupon c"));
    }

    private void seedReviews() {
        int inserted = 0;

        Map<String, Long> productIds = new LinkedHashMap<>();
        productIds.put("PRD-VEG-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-VEG-001"));
        productIds.put("PRD-BABY-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-BABY-001"));
        productIds.put("PRD-FISH-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-FISH-001"));
        productIds.put("PRD-SPORT-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-SPORT-001"));
        productIds.put("PRD-HOME-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-HOME-001"));
        productIds.put("PRD-GROC-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-GROC-001"));
        productIds.put("PRD-ACC-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-ACC-001"));
        productIds.put("PRD-TV-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-TV-001"));
        productIds.put("PRD-DEV-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-DEV-001"));
        productIds.put("PRD-MEN-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-MEN-001"));
        productIds.put("PRD-BEAUTY-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-BEAUTY-001"));
        productIds.put("PRD-ELEC-001", findId("select p.id from Product p where lower(p.tagNumber) = lower(:value)", "PRD-ELEC-001"));

        Map<String, Long> customerIds = new LinkedHashMap<>();
        customerIds.put("CUST-1001", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1001"));
        customerIds.put("CUST-1002", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1002"));
        customerIds.put("CUST-1003", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1003"));
        customerIds.put("CUST-1004", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1004"));
        customerIds.put("CUST-1005", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1005"));
        customerIds.put("CUST-1006", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1006"));
        customerIds.put("CUST-1007", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1007"));
        customerIds.put("CUST-1008", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1008"));
        customerIds.put("CUST-1009", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1009"));
        customerIds.put("CUST-1010", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1010"));
        customerIds.put("CUST-1011", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1011"));
        customerIds.put("CUST-1012", findId("select c.id from Customer c where lower(c.customerCode) = lower(:value)", "CUST-1012"));

        for (Review review : List.of(
                createReview("REV-260401", productIds.get("PRD-VEG-001"), "Fresh Vegetable Basket", customerIds.get("CUST-1001"), "Sania Akter", "sania.akter@styleora.test", 5, "Very fresh vegetables", "Everything arrived crisp and fresh.", "Approved", LocalDate.of(2026, 4, 4), "Thank you for the feedback."),
                createReview("REV-260402", productIds.get("PRD-BABY-001"), "Organic Baby Food Pack", customerIds.get("CUST-1002"), "Afrin Sultana", "afrin.sultana@styleora.test", 4, "Good for quick feeding", "Packaging was neat and product quality was solid.", "Approved", LocalDate.of(2026, 4, 10), "Glad it helped."),
                createReview("REV-260403", productIds.get("PRD-FISH-001"), "Premium River Fish Combo", customerIds.get("CUST-1003"), "Rahim Uddin", "rahim.uddin@styleora.test", 3, "Taste was fine", "Expected slightly larger cuts but quality was acceptable.", "Pending", LocalDate.of(2026, 4, 17), ""),
                createReview("REV-260404", productIds.get("PRD-SPORT-001"), "Adjustable Dumbbell Set", customerIds.get("CUST-1004"), "Maisha Rahman", "maisha.rahman@styleora.test", 5, "Excellent training gear", "Build quality is strong and weight switching is easy.", "Approved", LocalDate.of(2026, 4, 21), "Great to hear."),
                createReview("REV-260405", productIds.get("PRD-HOME-001"), "Modern Wall Decor Set", customerIds.get("CUST-1005"), "Karim Hasan", "karim.hasan@styleora.test", 2, "Color mismatch", "Looked different from the listing photos.", "Rejected", LocalDate.of(2026, 4, 27), "We will recheck the listing."),
                createReview("REV-260406", productIds.get("PRD-GROC-001"), "Premium Rice & Spice Bundle", customerIds.get("CUST-1006"), "Nusrat Jahan", "nusrat.jahan@styleora.test", 5, "Excellent pantry pack", "Very convenient bundle for monthly groceries.", "Approved", LocalDate.of(2026, 5, 3), "Thanks for shopping with us."),
                createReview("REV-260407", productIds.get("PRD-ACC-001"), "Fast Charger Cable Kit", customerIds.get("CUST-1007"), "Sakiba Noor", "sakiba.noor@styleora.test", 4, "Useful accessory combo", "Charging speed is good and cable quality feels durable.", "Approved", LocalDate.of(2026, 5, 9), "Appreciate the review."),
                createReview("REV-260408", productIds.get("PRD-TV-001"), "43 Inch Smart Television", customerIds.get("CUST-1008"), "Swarna Das", "swarna.das@styleora.test", 5, "Great display quality", "The screen is bright and setup was simple.", "Approved", LocalDate.of(2026, 5, 14), "Happy to know that."),
                createReview("REV-260409", productIds.get("PRD-DEV-001"), "Smart Home Mini Camera", customerIds.get("CUST-1009"), "Tanvir Ahmed", "tanvir.ahmed@styleora.test", 3, "Decent camera", "Needs a better mobile app but hardware is okay.", "Pending", LocalDate.of(2026, 5, 20), ""),
                createReview("REV-260410", productIds.get("PRD-MEN-001"), "Men Casual Sneaker", customerIds.get("CUST-1010"), "Jannat Ara", "jannat.ara@styleora.test", 4, "Nice casual pair", "Comfortable and looks clean in person.", "Approved", LocalDate.of(2026, 5, 25), "Thanks for sharing."),
                createReview("REV-260411", productIds.get("PRD-BEAUTY-001"), "Skin Care Essentials Box", customerIds.get("CUST-1011"), "Mahin Chowdhury", "mahin.chowdhury@styleora.test", 2, "Not for sensitive skin", "A couple of items did not suit me well.", "Rejected", LocalDate.of(2026, 5, 30), "Sorry about the experience."),
                createReview("REV-260412", productIds.get("PRD-ELEC-001"), "Android Tablet 10.1", customerIds.get("CUST-1012"), "Fariha Anjum", "fariha.anjum@styleora.test", 5, "Excellent value tablet", "Smooth for streaming and reading.", "Approved", LocalDate.of(2026, 6, 5), "Thank you.")
        )) {
            if (review.getProductId() == null) {
                continue;
            }

            if (exists("select count(r) from Review r where lower(r.reviewCode) = lower(:value)", review.getReviewCode())) {
                continue;
            }

            entityManager.persist(review);
            inserted++;
        }

        entityManager.flush();
        LOGGER.info("Sample seed: reviews inserted={}, total={}", inserted, count("select count(r) from Review r"));
    }

    private void cleanupSeededShipments() {
        List<String> seededTrackingNumbers = List.of(
                "SHIP-260401",
                "SHIP-260402",
                "SHIP-260403",
                "SHIP-260404",
                "SHIP-260406",
                "SHIP-260407",
                "SHIP-260408",
                "SHIP-260409",
                "SHIP-260410",
                "SHIP-260412"
        );

        List<Long> seededShipmentIds = new ArrayList<>();
        for (String trackingNumber : seededTrackingNumbers) {
            List<Long> matches = entityManager.createQuery(
                            "select s.id from Shipment s where lower(coalesce(s.trackingNumber, '')) = lower(:trackingNumber)",
                            Long.class
                    )
                    .setParameter("trackingNumber", trackingNumber)
                    .getResultList();
            seededShipmentIds.addAll(matches);
        }

        if (seededShipmentIds.isEmpty()) {
            return;
        }

        int deleted = entityManager.createQuery("delete from Shipment s where s.id in :ids")
                .setParameter("ids", seededShipmentIds)
                .executeUpdate();
        entityManager.flush();
        LOGGER.info("Sample seed cleanup: removed seeded shipments={}, remaining={}", deleted, count("select count(s) from Shipment s"));
    }

    private void logTotals() {
        LOGGER.info(
                "Sample seed totals => customers={}, products={}, warehouses={}, shippingMethods={}, purchases={}, purchaseOrders={}, purchaseReturns={}, orders={}, invoices={}, payments={}, coupons={}, reviews={}, shipments={}",
                count("select count(c) from Customer c"),
                count("select count(p) from Product p"),
                count("select count(w) from Warehouse w"),
                count("select count(s) from ShippingMethod s"),
                count("select count(p) from Purchase p"),
                count("select count(p) from PurchaseOrder p"),
                count("select count(p) from PurchaseReturn p"),
                count("select count(o) from Order o"),
                count("select count(i) from Invoice i"),
                count("select count(p) from Payment p"),
                count("select count(c) from Coupon c"),
                count("select count(r) from Review r"),
                count("select count(s) from Shipment s")
        );
    }

    private Customer createCustomer(String code, String fullName, String email, String phone, String gender,
                                    LocalDate dateOfBirth, String address, String city, Integer totalOrders,
                                    double totalSpend, String status, LocalDate registeredAt) {
        Customer customer = new Customer();
        customer.setCustomerCode(code);
        customer.setFullName(fullName);
        customer.setEmail(email);
        customer.setPhone(phone);
        customer.setGender(gender);
        customer.setDateOfBirth(dateOfBirth);
        customer.setAddress(address);
        customer.setCity(city);
        customer.setCountry("Bangladesh");
        customer.setTotalOrders(totalOrders);
        customer.setTotalSpend(totalSpend);
        customer.setStatus(status);
        customer.setRegisteredAt(registeredAt);
        customer.setNotes("ERP sample customer");
        return customer;
    }

    private Product createProduct(String tagNumber, String name, String category, String brand, String weight,
                                  String gender, double price, double discount, double tax, int stock) {
        Product product = new Product();
        product.setTagNumber(tagNumber);
        product.setName(name);
        product.setCategory(category);
        product.setBrand(brand);
        product.setWeight(weight);
        product.setGender(gender);
        product.setDescription(name + " sample product");
        product.setStock(stock);
        product.setTag("Featured");
        product.setPrice(BigDecimal.valueOf(price));
        product.setDiscount(BigDecimal.valueOf(discount));
        product.setTax(BigDecimal.valueOf(tax));
        product.setImageUrl("");
        return product;
    }

    private Warehouse createWarehouse(String warehouseId, String warehouseName, String location, String manager,
                                      String contactNumber, int stockAvailable, int stockShipping, double revenue) {
        Warehouse warehouse = new Warehouse();
        warehouse.setWarehouseId(warehouseId);
        warehouse.setWarehouseName(warehouseName);
        warehouse.setLocation(location);
        warehouse.setManager(manager);
        warehouse.setContactNumber(contactNumber);
        warehouse.setStockAvailable(stockAvailable);
        warehouse.setStockShipping(stockShipping);
        warehouse.setWarehouseRevenue(revenue);
        return warehouse;
    }

    private ShippingMethod createShippingMethod(String name, String description, String coverageArea, String courierName,
                                                double cost, double minOrderAmount, double maxWeightKg, boolean isFreeShipping,
                                                int estimatedDays, int sortOrder, String status) {
        ShippingMethod shippingMethod = new ShippingMethod();
        shippingMethod.setName(name);
        shippingMethod.setDescription(description);
        shippingMethod.setCoverageArea(coverageArea);
        shippingMethod.setCourierName(courierName);
        shippingMethod.setCost(cost);
        shippingMethod.setMinOrderAmount(minOrderAmount);
        shippingMethod.setMaxWeightKg(maxWeightKg);
        shippingMethod.setIsFreeShipping(isFreeShipping);
        shippingMethod.setEstimatedDays(estimatedDays);
        shippingMethod.setSortOrder(sortOrder);
        shippingMethod.setStatus(status);
        return shippingMethod;
    }

    private Purchase createPurchase(String purchaseId, String orderBy, String supplierEmail, String supplierPhone,
                                    String supplierAddress, String items, String purchaseStatus, LocalDate purchaseDate,
                                    double total, String paymentMethod, String paymentStatus, double subtotal,
                                    double discount, double tax, double shippingCost, double paidAmount, double dueAmount,
                                    String notes) {
        Purchase purchase = new Purchase();
        purchase.setPurchaseId(purchaseId);
        purchase.setSupplierName(orderBy);
        purchase.setOrderBy(orderBy);
        purchase.setSupplierEmail(supplierEmail);
        purchase.setSupplierPhone(supplierPhone);
        purchase.setSupplierAddress(supplierAddress);
        purchase.setItems(items);
        purchase.setPurchaseStatus(purchaseStatus);
        purchase.setPurchaseDate(purchaseDate);
        purchase.setTotal(total);
        purchase.setPaymentMethod(paymentMethod);
        purchase.setPaymentStatus(paymentStatus);
        purchase.setSubtotal(subtotal);
        purchase.setDiscount(discount);
        purchase.setTax(tax);
        purchase.setShippingCost(shippingCost);
        purchase.setPaidAmount(paidAmount);
        purchase.setDueAmount(dueAmount);
        purchase.setNotes(notes);
        purchase.setStockApplied(false);
        return purchase;
    }

    private PurchaseOrder createPurchaseOrder(String purchaseOrderId, String supplierName, String supplierEmail,
                                              String supplierPhone, String supplierAddress, LocalDate orderDate,
                                              LocalDate expectedDeliveryDate, String orderStatus, String paymentStatus,
                                              String paymentMethod, String items, double subtotal, double discount,
                                              double tax, double shippingCost, double totalAmount, double paidAmount,
                                              double dueAmount, String notes) {
        PurchaseOrder purchaseOrder = new PurchaseOrder();
        purchaseOrder.setPurchaseOrderId(purchaseOrderId);
        purchaseOrder.setSupplierName(supplierName);
        purchaseOrder.setSupplierEmail(supplierEmail);
        purchaseOrder.setSupplierPhone(supplierPhone);
        purchaseOrder.setSupplierAddress(supplierAddress);
        purchaseOrder.setOrderDate(orderDate);
        purchaseOrder.setExpectedDeliveryDate(expectedDeliveryDate);
        purchaseOrder.setOrderStatus(orderStatus);
        purchaseOrder.setPaymentStatus(paymentStatus);
        purchaseOrder.setPaymentMethod(paymentMethod);
        purchaseOrder.setItems(items);
        purchaseOrder.setSubtotal(subtotal);
        purchaseOrder.setDiscount(discount);
        purchaseOrder.setTax(tax);
        purchaseOrder.setShippingCost(shippingCost);
        purchaseOrder.setTotalAmount(totalAmount);
        purchaseOrder.setPaidAmount(paidAmount);
        purchaseOrder.setDueAmount(dueAmount);
        purchaseOrder.setNotes(notes);
        return purchaseOrder;
    }

    private PurchaseReturn createPurchaseReturn(String returnId, String purchaseOrderId, String supplierName,
                                                String supplierEmail, String supplierPhone, LocalDate returnDate,
                                                String returnReason, String returnStatus, String refundStatus,
                                                String paymentMethod, String items, double subtotal, double tax,
                                                double discount, double totalAmount, String notes) {
        PurchaseReturn purchaseReturn = new PurchaseReturn();
        purchaseReturn.setReturnId(returnId);
        purchaseReturn.setPurchaseOrderId(purchaseOrderId);
        purchaseReturn.setSupplierName(supplierName);
        purchaseReturn.setSupplierEmail(supplierEmail);
        purchaseReturn.setSupplierPhone(supplierPhone);
        purchaseReturn.setReturnDate(returnDate);
        purchaseReturn.setReturnReason(returnReason);
        purchaseReturn.setReturnStatus(returnStatus);
        purchaseReturn.setRefundStatus(refundStatus);
        purchaseReturn.setPaymentMethod(paymentMethod);
        purchaseReturn.setItems(items);
        purchaseReturn.setSubtotal(subtotal);
        purchaseReturn.setTax(tax);
        purchaseReturn.setDiscount(discount);
        purchaseReturn.setTotalAmount(totalAmount);
        purchaseReturn.setNotes(notes);
        return purchaseReturn;
    }

    private Order createOrder(String orderId, LocalDate createdAt, String customerName, String customerEmail,
                              String customerPhone, String shippingAddress, String billingAddress, String priority,
                              double subtotal, double tax, double discount, double shippingCost, double totalAmount,
                              String paymentMethod, String paymentStatus, int items, String deliveryNumber,
                              String trackingNumber, String orderStatus) {
        Order order = new Order();
        order.setOrderId(orderId);
        order.setCreatedAt(createdAt);
        order.setCustomerName(customerName);
        order.setCustomerEmail(customerEmail);
        order.setCustomerPhone(customerPhone);
        order.setShippingAddress(shippingAddress);
        order.setBillingAddress(billingAddress);
        order.setPriority(priority);
        order.setSubtotal(subtotal);
        order.setTax(tax);
        order.setDiscount(discount);
        order.setShippingCost(shippingCost);
        order.setTotalAmount(totalAmount);
        order.setPaymentMethod(paymentMethod);
        order.setPaymentStatus(paymentStatus);
        order.setItems(items);
        order.setDeliveryNumber(deliveryNumber);
        order.setTrackingNumber(trackingNumber);
        order.setOrderStatus(orderStatus);
        return order;
    }

    private Invoice createInvoice(String invoiceNumber, String orderCode, String customerName, String customerEmail,
                                  String billingAddress, double subtotal, double tax, double discount,
                                  double shippingCost, double totalAmount, String paymentStatus,
                                  String paymentMethod, LocalDate issueDate, LocalDate dueDate) {
        Invoice invoice = new Invoice();
        invoice.setInvoiceNumber(invoiceNumber);
        invoice.setOrderId(findId("select o.id from Order o where lower(o.orderId) = lower(:value)", orderCode));
        invoice.setCustomerName(customerName);
        invoice.setCustomerEmail(customerEmail);
        invoice.setBillingAddress(billingAddress);
        invoice.setSubtotal(subtotal);
        invoice.setTax(tax);
        invoice.setDiscount(discount);
        invoice.setShippingCost(shippingCost);
        invoice.setTotalAmount(totalAmount);
        invoice.setPaymentStatus(paymentStatus);
        invoice.setPaymentMethod(paymentMethod);
        invoice.setIssueDate(issueDate);
        invoice.setDueDate(dueDate);
        invoice.setNotes("ERP sample invoice");
        return invoice;
    }

    private Payment createPayment(String transactionId, String invoiceNumber, String orderCode, String customerName,
                                  double amount, String paymentMethod, String paymentStatus, LocalDate paymentDate,
                                  String notes) {
        Payment payment = new Payment();
        payment.setTransactionId(transactionId);
        payment.setInvoiceId(findId("select i.id from Invoice i where lower(i.invoiceNumber) = lower(:value)", invoiceNumber));
        payment.setOrderId(findId("select o.id from Order o where lower(o.orderId) = lower(:value)", orderCode));
        payment.setCustomerName(customerName);
        payment.setAmount(amount);
        payment.setPaymentMethod(paymentMethod);
        payment.setPaymentStatus(paymentStatus);
        payment.setPaymentDate(paymentDate);
        payment.setNotes(notes);
        payment.setCreatedAt(paymentDate);
        payment.setUpdatedAt(paymentDate);
        return payment;
    }

    private Coupon createCoupon(String couponCode, String discountType, double discountValue, LocalDate startDate,
                                LocalDate endDate, int usageLimit, int usedCount, double minimumOrderAmount,
                                String status, String description) {
        Coupon coupon = new Coupon();
        coupon.setCouponCode(couponCode);
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(discountValue);
        coupon.setStartDate(startDate);
        coupon.setEndDate(endDate);
        coupon.setUsageLimit(usageLimit);
        coupon.setUsedCount(usedCount);
        coupon.setMinimumOrderAmount(minimumOrderAmount);
        coupon.setStatus(status);
        coupon.setDescription(description);
        coupon.setCreatedAt(startDate);
        coupon.setUpdatedAt(startDate);
        return coupon;
    }

    private Review createReview(String reviewCode, Long productId, String productName, Long customerId,
                                String customerName, String customerEmail, int rating, String reviewTitle,
                                String reviewMessage, String reviewStatus, LocalDate reviewDate, String replyMessage) {
        Review review = new Review();
        review.setReviewCode(reviewCode);
        review.setProductId(productId);
        review.setProductName(productName);
        review.setCustomerId(customerId);
        review.setCustomerName(customerName);
        review.setCustomerEmail(customerEmail);
        review.setRating(rating);
        review.setReviewTitle(reviewTitle);
        review.setReviewMessage(reviewMessage);
        review.setReviewStatus(reviewStatus);
        review.setReviewDate(reviewDate);
        review.setReplyMessage(replyMessage);
        review.setCreatedAt(reviewDate);
        review.setUpdatedAt(reviewDate);
        return review;
    }

    private String purchaseItems(String product, String sku, int quantity, double unitCost, double discount, double tax, double total) {
        return "[{\"product\":\"" + product + "\",\"sku\":\"" + sku + "\",\"quantity\":" + quantity +
                ",\"unitCost\":" + unitCost + ",\"discount\":" + discount + ",\"tax\":" + tax + ",\"total\":" + total + "}]";
    }

    private boolean exists(String query, String value) {
        Long count = entityManager.createQuery(query, Long.class)
                .setParameter("value", value)
                .getSingleResult();
        return count != null && count > 0;
    }

    private long count(String query) {
        Long total = entityManager.createQuery(query, Long.class).getSingleResult();
        return total == null ? 0 : total;
    }

    private Long findId(String query, String value) {
        try {
            return entityManager.createQuery(query, Long.class)
                    .setParameter("value", value)
                    .getSingleResult();
        } catch (NoResultException exception) {
            return null;
        }
    }
}
