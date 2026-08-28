const express = require("express");
const router = express.Router();
const Sale = require("../models/Sale");
const { recordStockMovement } = require("../services/stockService");

// Get all sales
router.get("/", async (req, res) => {
  try {
    const sales = await Sale.find().sort({ date: -1 });
    res.json(sales);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create a new sale — stock is decremented atomically via stockService
router.post("/", async (req, res) => {
  const mode = req.body.payMode || req.body.paymentMode || req.body.payment_mode || req.body.paymentMethod || "Cash";
  const saleData = { ...req.body, payMode: mode, paymentMode: mode };

  const sale = new Sale(saleData);
  try {
    const newSale = await sale.save();

    // Decrease stock for each item via central stock service
    const stockErrors = [];
    for (const item of newSale.items) {
      if (item.medicineId && item.medicineId.length === 24) {
        try {
          await recordStockMovement({
            medicineId: item.medicineId,
            type: "SALE",
            quantity: item.quantity,
            referenceId: newSale._id.toString(),
            reason: `POS Sale - Invoice ${newSale.invoiceNumber}`,
            userId: "pos",
          });
        } catch (err) {
          stockErrors.push({
            medicineId: item.medicineId,
            medicineName: item.medicineName,
            error: err.message,
          });
        }
      }
    }

    if (stockErrors.length > 0) {
      res.status(201).json({
        sale: newSale,
        warnings: stockErrors,
        message:
          "Sale created but some stock updates failed. Check warnings.",
      });
    } else {
      res.status(201).json(newSale);
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete all sales history
router.delete("/", async (req, res) => {
  try {
    const result = await Sale.deleteMany({});
    res.json({ message: "All sales deleted successfully", count: result.deletedCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete single sale by ID
router.delete("/:id", async (req, res) => {
  try {
    const sale = await Sale.findByIdAndDelete(req.params.id);
    if (!sale) {
      return res.status(404).json({ message: "Sale not found" });
    }
    res.json({ message: "Sale deleted successfully", id: req.params.id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
