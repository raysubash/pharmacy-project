const express = require("express");
const router = express.Router();
const Sale = require("../models/Sale");
const Medicine = require("../models/Medicine");

// Get all sales
router.get("/", async (req, res) => {
  try {
    const sales = await Sale.find().sort({ date: -1 });
    res.json(sales);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create a new sale
router.post("/", async (req, res) => {
  const sale = new Sale(req.body);
  try {
    const newSale = await sale.save();

    // Decrease stock
    for (const item of newSale.items) {
      // Assuming medicineId is the MongoDB _id
      // Use findByIdAndUpdate to decrease stock
      /*
             await Medicine.findByIdAndUpdate(item.medicineId, { 
                 $inc: { currentStock: -item.quantity } 
             });
             */
      // Since medicineId in flutter might be different, let's try to match by name or check if ID is valid
      // For now, logic to update stock is important
      if (item.medicineId && item.medicineId.length === 24) {
        await Medicine.findByIdAndUpdate(item.medicineId, {
          $inc: { currentStock: -item.quantity },
        });
      }
    }

    res.status(201).json(newSale);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

module.exports = router;
