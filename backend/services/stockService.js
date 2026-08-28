const Medicine = require("../models/Medicine");
const StockTransaction = require("../models/StockTransaction");
const mongoose = require("mongoose");

// Types that decrease stock
const STOCK_OUT_TYPES = ["SALE", "DAMAGE", "RETURN_OUT"];
// Types that increase stock
const STOCK_IN_TYPES = ["PURCHASE", "RETURN_IN", "INITIAL"];
// ADJUSTMENT can go either way — signedQuantity determines direction

/**
 * Central function for ALL stock changes.
 * No other code should directly modify Medicine.currentStock.
 *
 * @param {Object} params
 * @param {string} params.medicineId - MongoDB _id of the medicine
 * @param {string} params.type - One of: PURCHASE, SALE, RETURN_IN, RETURN_OUT, ADJUSTMENT, DAMAGE, INITIAL
 * @param {number} params.quantity - Positive number (absolute quantity)
 * @param {string} [params.referenceId] - ID of source document (invoice, bill, return)
 * @param {string} [params.reason] - Human-readable reason
 * @param {string} [params.userId] - Who performed this action
 * @returns {Object} { medicine, transaction } - Updated medicine and the created transaction
 */
async function recordStockMovement({
  medicineId,
  type,
  quantity,
  referenceId = null,
  reason = "",
  userId = "system",
}) {
  // Validate inputs
  if (!medicineId) throw new Error("medicineId is required");
  if (!type) throw new Error("type is required");
  if (quantity === undefined || quantity === null)
    throw new Error("quantity is required");

  const absQuantity = Math.abs(quantity);

  // Calculate signed quantity based on type
  let signedQuantity;
  if (type === "ADJUSTMENT") {
    // For ADJUSTMENT, quantity can be negative (stock decrease) or positive (stock increase)
    signedQuantity = quantity; // preserve sign as passed
  } else if (STOCK_OUT_TYPES.includes(type)) {
    signedQuantity = -absQuantity;
  } else if (STOCK_IN_TYPES.includes(type)) {
    signedQuantity = absQuantity;
  } else {
    throw new Error(`Invalid stock movement type: ${type}`);
  }

  // Build the atomic update query
  const updateQuery = { $inc: { currentStock: signedQuantity } };

  // For stock-out operations, ensure sufficient stock via query condition
  const findCondition = { _id: medicineId };
  if (signedQuantity < 0) {
    findCondition.currentStock = { $gte: absQuantity };
  }

  // Try with transaction first (requires replica set), fallback to without
  let useTransaction = true;
  let session = null;

  try {
    session = await mongoose.startSession();
    await session.startTransaction();
  } catch (err) {
    // Standalone MongoDB — transactions not supported, proceed without
    useTransaction = false;
    if (session) {
      try {
        session.endSession();
      } catch (_) {}
    }
    session = null;
  }

  try {
    const sessionOpts = useTransaction ? { session } : {};

    // 1. Atomically update medicine stock
    const medicine = await Medicine.findOneAndUpdate(
      findCondition,
      updateQuery,
      { new: true, ...sessionOpts },
    );

    if (!medicine) {
      // Either medicine not found or insufficient stock
      const exists = await Medicine.findById(medicineId);
      if (!exists) {
        throw new Error(`Medicine not found: ${medicineId}`);
      }
      throw new Error(
        `Insufficient stock. Current: ${exists.currentStock}, Requested: ${absQuantity}`,
      );
    }

    // 2. Create immutable transaction record
    const [transaction] = await StockTransaction.create(
      [
        {
          medicineId,
          type,
          quantity: absQuantity,
          signedQuantity,
          resultingQuantity: medicine.currentStock,
          referenceId,
          reason,
          createdBy: userId,
        },
      ],
      sessionOpts,
    );

    if (useTransaction) {
      await session.commitTransaction();
    }

    return { medicine, transaction };
  } catch (err) {
    if (useTransaction && session) {
      try {
        await session.abortTransaction();
      } catch (_) {}
    }
    throw err;
  } finally {
    if (session) {
      try {
        session.endSession();
      } catch (_) {}
    }
  }
}

/**
 * Get all stock transactions for a medicine, sorted newest first.
 */
async function getTransactionHistory(medicineId, { limit = 100 } = {}) {
  return StockTransaction.find({ medicineId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();
}

/**
 * Reconcile: compare sum of all transactions vs medicine's currentStock.
 * Returns { match, currentStock, calculatedStock, difference }
 */
async function reconcileStock(medicineId) {
  const medicine = await Medicine.findById(medicineId).lean();
  if (!medicine) throw new Error(`Medicine not found: ${medicineId}`);

  const result = await StockTransaction.aggregate([
    { $match: { medicineId: new mongoose.Types.ObjectId(medicineId) } },
    { $group: { _id: null, total: { $sum: "$signedQuantity" } } },
  ]);

  const calculatedStock = result.length > 0 ? result[0].total : 0;
  const currentStock = medicine.currentStock || 0;

  return {
    medicineId,
    medicineName: medicine.name,
    currentStock,
    calculatedStock,
    difference: currentStock - calculatedStock,
    match: currentStock === calculatedStock,
  };
}

/**
 * Reconcile all medicines. Returns array of mismatched entries.
 */
async function reconcileAll() {
  const medicines = await Medicine.find({}, "_id name currentStock").lean();
  const mismatches = [];

  for (const med of medicines) {
    const result = await reconcileStock(med._id.toString());
    if (!result.match) {
      mismatches.push(result);
    }
  }

  return mismatches;
}

module.exports = {
  recordStockMovement,
  getTransactionHistory,
  reconcileStock,
  reconcileAll,
};
