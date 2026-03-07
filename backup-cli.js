#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const backupDir = '/var/www';
const backupFileName = `www-backup-${new Date().toISOString().replace(/[:.]/g, '-')}.zip`;
const backupPath = path.join(__dirname, backupFileName);

console.log('Starting backup...');

// Check if directory exists
if (!fs.existsSync(backupDir)) {
    console.error(`Error: Directory ${backupDir} does not exist!`);
    process.exit(1);
}

// Create zip using zip command
const command = `zip -r "${backupPath}" "${backupDir}"`;

exec(command, (error, stdout, stderr) => {
    if (error) {
        console.error(`Error creating backup: ${error.message}`);
        return;
    }
    if (stderr) {
        console.error(`Warning: ${stderr}`);
    }
    
    console.log(`Backup completed successfully!`);
    console.log(`Backup saved to: ${backupPath}`);
    
    // Display file size
    const stats = fs.statSync(backupPath);
    const fileSizeInMB = stats.size / (1024 * 1024);
    console.log(`File size: ${fileSizeInMB.toFixed(2)} MB`);
});