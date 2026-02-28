const mongoose = require("mongoose");

const saleItemSchema = new mongoose.Schema({
  medicineId: { type: String, required: true },
  medicineName: { type: String, required: true },
  quantity: { type: Number, required: true },
  price: { type: Number, required: true },
  discount: { type: Number, default: 0 },
  total: { type: Number, required: true },
});

const saleSchema = new mongoose.Schema(
  {
    invoiceNumber: { type: String, required: true, unique: true },
    customerName: { type: String, required: true },
    customerPhone: { type: String },
    customerAddress: { type: String },
    items: [saleItemSchema],
    subTotal: { type: Number, required: true },
    discount: { type: Number, default: 0 },
    tax: { type: Number, default: 0 },
    grandTotal: { type: Number, required: true },
    paymentMethod: { type: String, default: "Cash" },
    date: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Sale", saleSchema);
