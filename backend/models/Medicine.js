const mongoose = require("mongoose");

const medicineSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    genericName: { type: String },
    category: { type: String, required: true },
    unit: {
      type: String,
      enum: ["tablet", "syrup", "capsule", "injection", "other"],
      required: true,
    },
    minStock: { type: Number, required: true },
    sellingPrice: { type: Number, required: true },
    storageLocation: { type: String },
    currentStock: { type: Number, default: 0 },
    brandName: { type: String },
    packaging: { type: String },
    mrp: { type: Number },
    imagePath: { type: String },
    batchNumber: { type: String },
    expiryDate: { type: Date },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Medicine", medicineSchema);
