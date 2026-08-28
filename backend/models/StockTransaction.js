const mongoose = require("mongoose");

const stockTransactionSchema = new mongoose.Schema(
  {
    medicineId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Medicine",
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: [
        "PURCHASE",
        "SALE",
        "RETURN_IN",
        "RETURN_OUT",
        "ADJUSTMENT",
        "DAMAGE",
        "INITIAL",
      ],
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 0,
    },
    // Positive for stock-in, negative for stock-out
    signedQuantity: {
      type: Number,
      required: true,
    },
    // Medicine's currentStock after this transaction was applied
    resultingQuantity: {
      type: Number,
      required: true,
    },
    // Reference to the source document (Sale invoice, Bill ID, Return ID)
    referenceId: {
      type: String,
      default: null,
    },
    reason: {
      type: String,
      default: "",
    },
    createdBy: {
      type: String,
      default: "system",
    },
  },
  { timestamps: true },
);

// Index for fast lookups: transaction history per medicine, sorted by time
stockTransactionSchema.index({ medicineId: 1, createdAt: -1 });

module.exports = mongoose.model("StockTransaction", stockTransactionSchema);
