const express = require("express");
const router = express.Router();
const ReturnItem = require("../models/Return");
const Medicine = require("../models/Medicine");
const { recordStockMovement } = require("../services/stockService");

// Get all returns
router.get("/", async (req, res) => {
  try {
    const returns = await ReturnItem.find();
    res.json(returns);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create return — stock adjusted when return is created
router.post("/", async (req, res) => {
  const returnItem = new ReturnItem(req.body);
  try {
    const newReturn = await returnItem.save();

    // Try to find the medicine by name to get its ID for stock adjustment
    // Since returnItem doesn't have medicineId, we look up by name
    let stockWarning = null;
    try {
      const medicine = await Medicine.findOne({
        name: newReturn.medicineName,
      });
      if (medicine) {
        await recordStockMovement({
          medicineId: medicine._id.toString(),
          type: "RETURN_OUT",
          quantity: newReturn.quantity,
          referenceId: newReturn._id.toString(),
          reason: `Return to Supplier - ${newReturn.reason}`,
          userId: "return",
        });
      } else {
        stockWarning = `Medicine '${newReturn.medicineName}' not found for stock adjustment`;
      }
    } catch (stockErr) {
      stockWarning = stockErr.message;
    }

    if (stockWarning) {
      res.status(201).json({
        return: newReturn,
        warning: stockWarning,
      });
    } else {
      res.status(201).json(newReturn);
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update return status
router.put("/:id", async (req, res) => {
  try {
    const updatedReturn = await ReturnItem.findByIdAndUpdate(
      req.params.id,
      req.body,
      { returnDocument: "after" },
    );
    res.json(updatedReturn);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete return
router.delete("/:id", async (req, res) => {
  try {
    await ReturnItem.findByIdAndDelete(req.params.id);
    res.json({ message: "Return deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
