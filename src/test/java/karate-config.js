function fn() {
  var config = {
    authUrl: 'http://134.209.211.10:4001',
    walletUrl: 'http://134.209.211.10:4002',
    transactionUrl: 'http://134.209.211.10:4003',
    adminUrl: 'http://134.209.211.10:4004'
  };
  karate.configure('connectTimeout', 5000);
  karate.configure('readTimeout', 5000);
  return config;
}