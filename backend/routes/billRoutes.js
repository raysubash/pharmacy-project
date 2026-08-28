const express = require("express");
const router = express.Router();
const PurchaseBill = require("../models/Bill");
const { recordStockMovement } = require("../services/stockService");

// Get all bills
router.get("/", async (req, res) => {
  try {
    const bills = await PurchaseBill.find();
    res.json(bills);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get one bill
router.get("/:id", async (req, res) => {
  try {
    const bill = await PurchaseBill.findById(req.params.id);
    if (bill) {
      res.json(bill);
    } else {
      res.status(404).json({ message: "Bill not found" });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create bill — stock is increased via stockService for each item
router.post("/", async (req, res) => {
  const bill = new PurchaseBill(req.body);
  try {
    const newBill = await bill.save();

    // Increase medicine stock for each purchased item
    const stockErrors = [];
    for (const item of newBill.items) {
      if (item.medicineId && item.medicineId.length === 24) {
        try {
          await recordStockMovement({
            medicineId: item.medicineId,
            type: "PURCHASE",
            quantity: item.quantity,
            referenceId: newBill._id.toString(),
            reason: `Purchase Bill - ${newBill.billNumber} from ${newBill.supplierName}`,
            userId: "purchase",
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
        bill: newBill,
        warnings: stockErrors,
        message:
          "Bill created but some stock updates failed. Check warnings.",
      });
    } else {
      res.status(201).json(newBill);
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete bill
router.delete("/:id", async (req, res) => {
  try {
    await PurchaseBill.findByIdAndDelete(req.params.id);
    res.json({ message: "Bill deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
