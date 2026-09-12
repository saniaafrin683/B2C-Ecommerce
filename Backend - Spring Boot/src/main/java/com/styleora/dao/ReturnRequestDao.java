package com.styleora.dao;

import com.styleora.model.ReturnRequest;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class ReturnRequestDao {

    @PersistenceContext
    private EntityManager entityManager;

    public ReturnRequest saveReturnRequest(ReturnRequest returnRequest) {
        returnRequest.setId(null);
        entityManager.persist(returnRequest);
        entityManager.flush();
        return returnRequest;
    }

    public List<ReturnRequest> getAllReturnRequests() {
        return entityManager
                .createQuery("from ReturnRequest rr order by rr.requestedAt desc, rr.id desc", ReturnRequest.class)
                .getResultList();
    }

    public List<ReturnRequest> getReturnRequestsByCustomerId(Long customerId) {
        return entityManager.createQuery(
                        "from ReturnRequest rr where rr.customerId = :customerId order by rr.requestedAt desc, rr.id desc",
                        ReturnRequest.class
                )
                .setParameter("customerId", customerId)
                .getResultList();
    }

    public ReturnRequest getReturnRequestById(Long id) {
        return entityManager.find(ReturnRequest.class, id);
    }

    public ReturnRequest getReturnRequestByIdForUpdate(Long id) {
        return entityManager.find(ReturnRequest.class, id, LockModeType.PESSIMISTIC_WRITE);
    }

    public ReturnRequest getReturnRequestByOrderIdAndCustomerId(Long orderId, Long customerId) {
        List<ReturnRequest> result = entityManager.createQuery(
                        "from ReturnRequest rr where rr.orderId = :orderId and rr.customerId = :customerId",
                        ReturnRequest.class
                )
                .setParameter("orderId", orderId)
                .setParameter("customerId", customerId)
                .setMaxResults(1)
                .getResultList();
        return result.isEmpty() ? null : result.get(0);
    }

    public ReturnRequest updateReturnRequest(ReturnRequest returnRequest) {
        ReturnRequest mergedRequest = entityManager.merge(returnRequest);
        entityManager.flush();
        return mergedRequest;
    }

    public boolean deleteReturnRequest(Long id) {
        ReturnRequest returnRequest = entityManager.find(ReturnRequest.class, id);
        if (returnRequest == null) {
            return false;
        }

        entityManager.remove(returnRequest);
        entityManager.flush();
        return true;
    }

    public int deleteReturnRequestsByOrderId(Long orderId) {
        int deleted = entityManager.createQuery("delete from ReturnRequest rr where rr.orderId = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }
}
