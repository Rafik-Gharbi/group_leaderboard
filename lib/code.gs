/**
 * SYNC GOOGLE SHEETS → FIRESTORE
 * Works with your spreadsheet and pushes all rows to a Firestore collection.
 */

const PROJECT_ID = 'group-leaderboard-a8d51';
const COLLECTION_NAME = 'scores';
const FIREBASE_WEB_API_KEY = 'AIzaSyAkeGqXMcWe4JsXhgJnZK2G0JlnCa1LfjY'; // optional if using service account

// You can use a service account for better security:
const FIREBASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:batchWrite`;

function syncToFirestore() {
  const sheet = SpreadsheetApp.openById('1bxr75FGPjoyX_Uqg7R50Aym82Wxe5gRcDgbtzw0yaUE').getActiveSheet();
  const accessToken = getAccessToken(); 
  const range = sheet.getDataRange();
  const values = range.getValues();

  const headers = values[3]; // first row = headers
  const subHeaders = values[4]; // first row = headers
  const groupIndex = headers.indexOf('Group');
  const nameIndex = headers.indexOf('Student Name');
  const totalIndex = headers.indexOf('Total Score');
  const startIndex = subHeaders.indexOf('Starting Score');
  const extraIndex = headers.indexOf('Extra XP');
  const practiceIndex = headers.indexOf('Practice');

  // assignments = all columns between Student Name and Total Score excluding known ones
  const assignmentStart = nameIndex + 1;
  const assignmentEnd = totalIndex - 1;

  const writes = [];

  let success = 0;
  let errors = [];
  let group = "";

  values.slice(5).forEach((row) => {
    group = row[groupIndex].toString().startsWith('G') ? row[groupIndex] : group;
    const name = row[nameIndex];
    const total = row[totalIndex] || 0;
    const startingScore = row[startIndex] || 0;
    const extraXP = row[extraIndex] || 0;
    const practiceXP = row[practiceIndex] || 0;
    const assignments = {};

    if (!group || !name) return; // skip incomplete rows

    for (let i = assignmentStart; i <= assignmentEnd; i++) {
      const colName = subHeaders[i];
      assignments[colName] = row[i] || 0;
    }

    const docId = `${group}_${name.replace(/\s+/g, '_')}`;
    const docName = `projects/${PROJECT_ID}/databases/(default)/documents/scores/${docId}`;

    writes.push({
      update: {
        name: docName,
        fields: {
          group: { stringValue: group },
          studentName: { stringValue: name },
          assignments: { mapValue: { fields: Object.fromEntries(Object.entries(assignments).map(([k,v]) => [k, { integerValue: v }])) } },
          startingScore: { integerValue: startingScore },
          extraXP: { integerValue: extraXP },
          practiceXP: { integerValue: practiceXP },
          totalScore: { integerValue: total },
          updatedAt: { timestampValue: new Date().toISOString() },
        },
      },
    });
  });

  const payload = { writes: writes };
  try {
      const response = UrlFetchApp.fetch(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:batchWrite`, {
      method: 'post',
      contentType: 'application/json',
      headers: { Authorization: `Bearer ${accessToken}` },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true,
    });

    if (response.getResponseCode() === 200) success++;
    else errors.push(`Error ${response.getResponseCode()}`);
  } catch (e) {
    errors.push(`Exception: ${e}`);
  }

  Logger.log(`Sync complete: ${success} updated, ${errors.length} errors.`);
  if (errors.length) Logger.log(errors.join('\n'));
}

/**
 * Get OAuth2 access token from Service Account JSON stored in Script Properties
 */
function getAccessToken() {
  const key = JSON.parse(PropertiesService.getScriptProperties().getProperty('SERVICE_ACCOUNT_KEY'));

  const jwtHeader = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const jwtClaim = {
    iss: key.client_email,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now
  };

  const base64Encode = (obj) => Utilities.base64EncodeWebSafe(JSON.stringify(obj));
  const jwtUnsigned = `${base64Encode(jwtHeader)}.${base64Encode(jwtClaim)}`;
  const signature = Utilities.base64EncodeWebSafe(
    Utilities.computeRsaSha256Signature(jwtUnsigned, key.private_key)
  );
  const jwt = `${jwtUnsigned}.${signature}`;

  const response = UrlFetchApp.fetch("https://oauth2.googleapis.com/token", {
    method: "post",
    contentType: "application/x-www-form-urlencoded",
    payload: {
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    },
  });

  return JSON.parse(response.getContentText()).access_token;
}

