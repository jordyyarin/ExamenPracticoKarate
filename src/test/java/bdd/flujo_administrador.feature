@FlujoAdministrador
Feature: Flujo de Administración Billetera Digital

  Background:
    * url adminUrl
    * configure headers = { x-channel: 'POSTMAN' }

  Scenario: Validar la transacción de la operación como Administrador
    # 1. Login del Administrador para obtener el token con permisos de superusuario
    Given path '/admin/v1/login'
    And request { username: 'admin', password: 'superpassword' }
    When method post
    Then status 200
    * def tokenAdmin = response.token

    # 2. Consultar el historial global de transacciones
    Given path '/admin/v1/transactions'
    And header Authorization = 'Bearer ' + tokenAdmin
    When method get
    Then status 200

    # 3. Filtrar y validar
    * def transac = karate.filter(response, function(x){ return x.amount == 450 || x.amount == 450.00 })

    # Ordenar por fecha descendente
    * eval transac.sort(function(a, b){ return new Date(b.date) - new Date(a.date) })

    * assert transac.length > 0
    * def transaccionEncontrada = transac[0]
    * karate.log('TRANSACCIÓN ENCONTRADA:', transaccionEncontrada)

    And match transaccionEncontrada.amount == 450