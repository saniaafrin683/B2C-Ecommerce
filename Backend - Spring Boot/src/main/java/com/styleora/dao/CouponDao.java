package com.styleora.dao;

import com.styleora.model.Coupon;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class CouponDao {

    private static final Logger LOGGER = LoggerFactory.getLogger(CouponDao.class);

    @PersistenceContext
    private EntityManager entityManager;

    public Coupon saveCoupon(Coupon coupon) {
        entityManager.persist(coupon);
        return coupon;
    }

    public List<Coupon> getAllCoupons() {
        return entityManager
                .createQuery("from Coupon c order by c.id desc", Coupon.class)
                .getResultList();
    }

    public Coupon getCouponById(Long id) {
        return entityManager.find(Coupon.class, id);
    }

    public Coupon findByCouponCode(String couponCode) {
        List<Coupon> coupons = entityManager.createQuery(
                "select c from Coupon c where lower(c.couponCode) = lower(:couponCode)",
                Coupon.class
        ).setParameter("couponCode", couponCode)
         .setMaxResults(1)
         .getResultList();

        return coupons.isEmpty() ? null : coupons.get(0);
    }

    public void incrementUsedCount(String couponCode) {
        Coupon coupon = findByCouponCode(couponCode);
        if (coupon == null) {
            return;
        }

        int currentUsedCount = coupon.getUsedCount() == null ? 0 : coupon.getUsedCount();
        coupon.setUsedCount(currentUsedCount + 1);
        coupon.setUpdatedAt(java.time.LocalDate.now());
    }

    public Coupon updateCoupon(Long id, Coupon coupon) {
        Coupon existingCoupon = entityManager.find(Coupon.class, id);

        if (existingCoupon == null) {
            return null;
        }

        existingCoupon.setCouponCode(coupon.getCouponCode());
        existingCoupon.setDiscountType(coupon.getDiscountType());
        existingCoupon.setDiscountValue(coupon.getDiscountValue());
        existingCoupon.setStartDate(coupon.getStartDate());
        existingCoupon.setEndDate(coupon.getEndDate());
        existingCoupon.setUsageLimit(coupon.getUsageLimit());
        existingCoupon.setUsedCount(coupon.getUsedCount());
        existingCoupon.setMinimumOrderAmount(coupon.getMinimumOrderAmount());
        existingCoupon.setStatus(coupon.getStatus());
        existingCoupon.setDescription(coupon.getDescription());
        existingCoupon.setCreatedAt(coupon.getCreatedAt());
        existingCoupon.setUpdatedAt(coupon.getUpdatedAt());

        return existingCoupon;
    }

    public boolean deleteCoupon(Long id) {
        Coupon coupon = entityManager.find(Coupon.class, id);
        if (coupon == null) {
            LOGGER.info("Coupon delete skipped because no entity was found for id={}", id);
            return false;
        }

        LOGGER.info("Deleting coupon entity id={}, code={}", id, coupon.getCouponCode());
        entityManager.remove(coupon);
        entityManager.flush();
        LOGGER.info("Coupon entity removed and flushed for id={}", id);
        return true;
    }
}
