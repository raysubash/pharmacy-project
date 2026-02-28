const mongoose = require("mongoose");

const billItemSchema = new mongoose.Schema({
  medicineId: { type: String, required: true }, // Store reference ID as string for now to match flutter model but usually referencing ObjectId
  medicineName: { type: String, required: true },
  batchNumber: { type: String, required: true },
  manufactureDate: { type: Date, required: true },
  expiryDate: { type: Date, required: true },
  quantity: { type: Number, required: true },
  purchasePrice: { type: Number, required: true },
  totalAmount: { type: Number, required: true },
});

const purchaseBillSchema = new mongoose.Schema(
  {
    billNumber: { type: String, required: true },
    supplierName: { type: String, required: true },
    billDate: { type: Date, required: true },
    items: [billItemSchema],
    totalAmount: { type: Number, required: true },
    entryDate: { type: Date, required: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model("PurchaseBill", purchaseBillSchema);
