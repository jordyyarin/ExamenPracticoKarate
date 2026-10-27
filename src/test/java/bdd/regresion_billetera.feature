@RegresionCompleta
Feature: Flujo de Regresion Billetera Digital

  Background:
    * def randomPhone = function() { return '9' + Math.floor(10000000 + Math.random() * 90000000); }
    * def phoneEmisor = (java.lang.System.getProperty('globalPhoneEmisor') != null) ? java.lang.System.getProperty('globalPhoneEmisor') : randomPhone()
    * def phoneReceptor = (java.lang.System.getProperty('globalPhoneReceptor') != null) ? java.lang.System.getProperty('globalPhoneReceptor') : randomPhone()
    * configure headers = { x-channel: 'POSTMAN' }

  # Escenario 01
  Scenario: Registro de Usuarios
    # 1. Crear Usuario Emisor
    Given url authUrl
    And path '/auth/v1/register'
    And request { phone: '#(phoneEmisor)', fullName: 'Jordy Yaringano', email: 'jordyyarin@gmail.com', pin: '306895' }
    When method post
    Then status 201
    And match response.message == 'Usuario creado exitosamente'
    * java.lang.System.setProperty('globalIdEmisor', response.user.id)
    * java.lang.System.setProperty('globalPhoneEmisor', phoneEmisor)

    # 2. Validar conflicto de usuario duplicado
    Given url authUrl
    And path '/auth/v1/register'
    And request { phone: '#(phoneEmisor)', fullName: 'Jordy Yaringano', email: 'jordyyarin@gmail.com', pin: '306895' }
    When method post
    Then status 409
    And match response.code == 'AUTH_006'

    # 3. Crear usuario Receptor
    Given url authUrl
    And path '/auth/v1/register'
    And request { phone: '#(phoneReceptor)', fullName: 'Myrella Fiestas', email: 'myrellafiestas@gmail.com', pin: '478947' }
    When method post
    Then status 201
    * java.lang.System.setProperty('globalIdReceptor', response.user.id)
    * java.lang.System.setProperty('globalPhoneReceptor', phoneReceptor)

    # 4. Login del Usuario Emisor
    Given url authUrl
    And path '/auth/v1/login'
    And request { phone: '#(phoneEmisor)', pin: '306895' }
    When method post
    Then status 200
    * def tokenEmisor = response.token

    # 5. Asignación de Saldo Inicial del Emisor
    Given url walletUrl
    And path '/wallet/v1/deposit'
    And header Authorization = 'Bearer ' + tokenEmisor
    And request { amount: 1000.00 }
    When method post
    Then status 200
    And match response.success == true

    # 6. Validación de Saldo Inicial del Emisor
    Given url walletUrl
    And path '/wallet/v1/balance'
    And header Authorization = 'Bearer ' + tokenEmisor
    When method get
    Then status 200
    And match response.balance == 1000.00
    * karate.set('globalSaldoEmisor', response.balance)

    # 7. Guardar los saldos actuales de cada usuario en variables globales
    Given url authUrl
    And path '/auth/v1/login'
    And request { phone: '#(phoneReceptor)', pin: '478947' }
    When method post
    Then status 200
    * def tokenReceptor = response.token

    Given url walletUrl
    And path '/wallet/v1/balance'
    And header Authorization = 'Bearer ' + tokenReceptor
    When method get
    Then status 200
    * karate.set('globalSaldoReceptor', response.balance)

  # Escenario 02
  Scenario: Transferencia del Usuario Emisor al Receptor
  # 1. Iniciar sesión con el Usuario Emisor y obtener el token actualizado
    Given url authUrl
    And path '/auth/v1/login'
    And request { phone: '#(java.lang.System.getProperty(\'globalPhoneEmisor\'))', pin: '306895' }
    When method post
    Then status 200
    * def tokenEmisorTransfer = response.token

    # 2. Realizar transferencia de saldo al Usuario Receptor
    Given url transactionUrl
    And path '/transaction/v1/transfer'
    And header Authorization = 'Bearer ' + tokenEmisorTransfer
    And request { recipientId: '#(java.lang.System.getProperty("globalIdReceptor"))', amount: 450.00, description: 'Pago de Servicios' }
    When method post
    Then status 200

    # 3. Validación de transación
    And match response.status == 'COMPLETED'

    # 4. Guardamos el código de transferencia
    * def temp = java.lang.System.setProperty('globalRefCode', response.referenceCode)

    # 5. Consultar el saldo actual del usuario Emisor
    Given url walletUrl
    And path '/wallet/v1/balance'
    And header Authorization = 'Bearer ' + tokenEmisorTransfer
    When method get
    Then status 200

    # 6. Validar la disminución del saldo comparando con el saldo inicial
    And match response.balance == 550.00
    * karate.set('globalSaldoEmisorActualizado', response.balance)

  # Escenario 03
  Scenario: Validación de Transferencia en Receptor
    # 1. Iniciar sesión con el Usuario Receptor y obtener el token actualizado
    Given url authUrl
    And path '/auth/v1/login'
    And request { phone: '#(java.lang.System.getProperty(\'globalPhoneReceptor\'))', pin: '478947' }
    When method post
    Then status 200
    * def tokenReceptorValidation = response.token

    # 2. Consultar saldo del Usuario Receptor
    Given url walletUrl
    And path '/wallet/v1/balance'
    And header Authorization = 'Bearer ' + tokenReceptorValidation
    When method get
    Then status 200

    # 3. Validar el saldo actual del Receptor
    And match response.balance == 450.00

    # 4. Consultar las transacciones del usuario Receptor
    #Given url transactionUrl
    #And path '/transaction/v1/history'
    #And header Authorization = 'Bearer ' + tokenReceptorValidation
    #When method get
    #Then status 200

    # 5. Validar que la última transacción coincida con el globalTransactionId(Escenario 2)
    #And match response.transactions[0].transactionId == globalTransactionId
    #And match response.transactions[0].amount == 450.00
