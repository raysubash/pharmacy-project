const express = require("express");
const router = express.Router();
const {
  recordStockMovement,
  getTransactionHistory,
  reconcileStock,
  reconcileAll,
} = require("../services/stockService");

// Record a stock movement (ADJUSTMENT, DAMAGE, INITIAL, etc.)
router.post("/movement", async (req, res) => {
  try {
    const { medicineId, type, quantity, referenceId, reason, userId } =
      req.body;

    if (!medicineId || !type || quantity === undefined) {
      return res
        .status(400)
        .json({ message: "medicineId, type, and quantity are required" });
    }

    // Only allow manual movement types from this endpoint
    const allowedTypes = [
      "ADJUSTMENT",
      "DAMAGE",
      "INITIAL",
      "RETURN_IN",
      "RETURN_OUT",
    ];
    if (!allowedTypes.includes(type)) {
      return res.status(400).json({
        message: `Type '${type}' not allowed via this endpoint. SALE and PURCHASE are handled automatically.`,
      });
    }

    const result = await recordStockMovement({
      medicineId,
      type,
      quantity,
      referenceId,
      reason,
      userId: userId || "manual",
    });

    res.status(201).json({
      message: "Stock movement recorded",
      medicine: result.medicine,
      transaction: result.transaction,
    });
  } catch (err) {
    const status = err.message.includes("Insufficient") ? 409 : 400;
    res.status(status).json({ message: err.message });
  }
});

// Get transaction history for a medicine
router.get("/transactions/:medicineId", async (req, res) => {
  try {
    const { medicineId } = req.params;
    const limit = parseInt(req.query.limit) || 100;

    const transactions = await getTransactionHistory(medicineId, { limit });
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Reconcile stock for a single medicine
router.get("/reconcile/:medicineId", async (req, res) => {
  try {
    const result = await reconcileStock(req.params.medicineId);
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Reconcile all medicines — returns mismatches only
router.post("/reconcile-all", async (req, res) => {
  try {
    const mismatches = await reconcileAll();
    res.json({
      totalMismatches: mismatches.length,
      mismatches,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
