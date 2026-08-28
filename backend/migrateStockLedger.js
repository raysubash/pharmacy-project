/**
 * Migration Script: Rebuild Stock Ledger from Existing Data
 * 
 * Purpose: Creates ADJUSTMENT (opening balance) transactions for all medicines
 * that currently have currentStock > 0, so the StockTransaction ledger
 * starts clean and reconciliation works from day one.
 * 
 * Run once after deploying the new stock system:
 *   node migrateStockLedger.js
 * 
 * Safe to re-run — checks for existing INITIAL/ADJUSTMENT records first.
 */

require("dotenv").config();
const mongoose = require("mongoose");
const Medicine = require("./models/Medicine");
const StockTransaction = require("./models/StockTransaction");

const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/pharmacy";

async function migrate() {
  console.log("🔄 Connecting to MongoDB...");
  await mongoose.connect(MONGO_URI);
  console.log("✅ Connected\n");

  const medicines = await Medicine.find({}).lean();
  console.log(`📦 Found ${medicines.length} medicines total\n`);

  let migrated = 0;
  let skipped = 0;
  let zeroStock = 0;

  for (const med of medicines) {
    const currentStock = med.currentStock || 0;

    // Skip medicines with zero stock — no opening balance needed
    if (currentStock === 0) {
      zeroStock++;
      continue;
    }

    // Check if this medicine already has any transaction records
    // If it does, it was already migrated or is using the new system
    const existingTx = await StockTransaction.findOne({
      medicineId: med._id,
    });

    if (existingTx) {
      console.log(
        `⏭️  SKIP: ${med.name} (already has transaction records)`,
      );
      skipped++;
      continue;
    }

    // Create opening balance transaction
    const transaction = new StockTransaction({
      medicineId: med._id,
      type: "ADJUSTMENT",
      quantity: Math.abs(currentStock),
      signedQuantity: currentStock, // positive = stock in
      resultingQuantity: currentStock,
      referenceId: null,
      reason: "Opening balance — legacy stock migration",
      createdBy: "migration-script",
    });

    await transaction.save();

    console.log(
      `✅ MIGRATED: ${med.name} → opening balance: ${currentStock}`,
    );
    migrated++;
  }

  console.log("\n" + "═".repeat(50));
  console.log(`📊 Migration Summary:`);
  console.log(`   Total medicines:  ${medicines.length}`);
  console.log(`   Migrated:         ${migrated}`);
  console.log(`   Skipped (exists): ${skipped}`);
  console.log(`   Zero stock:       ${zeroStock}`);
  console.log("═".repeat(50));

  // Verify reconciliation for migrated medicines
  console.log("\n🔍 Verifying reconciliation...");
  let mismatches = 0;

  for (const med of medicines) {
    if ((med.currentStock || 0) === 0) continue;

    const result = await StockTransaction.aggregate([
      { $match: { medicineId: med._id } },
      { $group: { _id: null, total: { $sum: "$signedQuantity" } } },
    ]);

    const calculatedStock = result.length > 0 ? result[0].total : 0;
    const actualStock = med.currentStock || 0;

    if (calculatedStock !== actualStock) {
      console.log(
        `⚠️  MISMATCH: ${med.name} — DB: ${actualStock}, Ledger: ${calculatedStock}`,
      );
      mismatches++;
    }
  }

  if (mismatches === 0) {
    console.log("✅ All reconciled — ledger matches database stock perfectly!");
  } else {
    console.log(`\n⚠️  ${mismatches} mismatches found — review manually`);
  }

  await mongoose.disconnect();
  console.log("\n👋 Done. Disconnected from MongoDB.");
}

migrate().catch((err) => {
  console.error("❌ Migration failed:", err);
  process.exit(1);
});
