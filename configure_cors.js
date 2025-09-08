const {Storage} = require('@google-cloud/storage');

async function configureCORS() {
  try {
    const storage = new Storage({
      projectId: 'chatapp-bb0e2',
    });

    const bucketName = 'chatapp-bb0e2.firebasestorage.app';
    const bucket = storage.bucket(bucketName);

    const corsConfiguration = [
      {
        origin: ['*'],
        method: ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'],
        maxAgeSeconds: 3600,
        responseHeader: [
          'Content-Type',
          'Access-Control-Allow-Origin',
          'Access-Control-Allow-Methods',
          'Access-Control-Allow-Headers',
          'Access-Control-Allow-Credentials'
        ]
      }
    ];

    await bucket.setCorsConfiguration(corsConfiguration);
    console.log('✅ CORS configuration updated successfully!');
    console.log('Bucket:', bucketName);
    console.log('CORS rules applied. Images should now display correctly.');
  } catch (error) {
    console.error('❌ Error configuring CORS:', error.message);
    console.log('Please try the Google Cloud Console method instead.');
  }
}

configureCORS(); 