const mongoose = require("mongoose");

const returnItemSchema = new mongoose.Schema(
  {
    medicineName: { type: String, required: true },
    batchNumber: { type: String, required: true },
    quantity: { type: Number, required: true },
    reason: { type: String, required: true },
    returnDate: { type: Date, required: true },
    refundAmount: { type: Number },
    status: {
      type: String,
      enum: ["Pending", "Approved", "Rejected", "Returned", "Reminder"],
      default: "Pending",
    },
    _id: { type: String }, // Allow string IDs from frontend UUIDs
    originalBillNo: { type: String },
    expiryDate: { type: Date },
    supplierName: { type: String },
  },
  { timestamps: true },
);

module.exports = mongoose.model("ReturnItem", returnItemSchema);
