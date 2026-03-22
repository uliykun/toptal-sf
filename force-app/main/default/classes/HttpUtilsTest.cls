@isTest
private class HttpUtilsTest {

    @isTest
    static void buildRequest_setsAllBaseProperties() {
        HttpRequest req = HttpUtils.buildRequest('GET', 'https://example.com/api', 5000);

        Assert.areEqual('GET', req.getMethod());
        Assert.areEqual('https://example.com/api', req.getEndpoint());
        Assert.areEqual('application/json', req.getHeader('Accept'));
    }

    @isTest
    static void buildJsonRequest_addsContentTypeAndBody() {
        String body = '{"key":"value"}';
        HttpRequest req = HttpUtils.buildJsonRequest('POST', 'https://example.com', body, 5000);

        Assert.areEqual('POST', req.getMethod());
        Assert.areEqual('application/json', req.getHeader('Content-Type'));
        Assert.areEqual(body, req.getBody());
    }

    @isTest
    static void buildJsonRequest_patchMethodIsSupported() {
        HttpRequest req = HttpUtils.buildJsonRequest('PATCH', 'https://example.com', '{}', 5000);

        Assert.areEqual('PATCH', req.getMethod());
    }

    @isTest
    static void responseWrapper_isSuccessOn200() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setStatus('OK');
        res.setBody('{"id":"abc"}');
        HttpUtils.ResponseWrapper w = new HttpUtils.ResponseWrapper(res);

        Assert.isTrue(w.isSuccess);
        Assert.areEqual(200, w.statusCode);
        Assert.areEqual('{"id":"abc"}', w.responseBody);
        Assert.isNull(w.errorMessage);
    }

    @isTest
    static void responseWrapper_isSuccessOn201() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(201);
        res.setStatus('Created');
        res.setBody('{}');
        HttpUtils.ResponseWrapper w = new HttpUtils.ResponseWrapper(res);

        Assert.isTrue(w.isSuccess);
    }

    @isTest
    static void responseWrapper_isFailureOn401() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(401);
        res.setStatus('Unauthorized');
        res.setBody('');
        HttpUtils.ResponseWrapper w = new HttpUtils.ResponseWrapper(res);

        Assert.isFalse(w.isSuccess);
        Assert.areEqual(401, w.statusCode);
        Assert.isTrue(w.errorMessage.contains('401'));
    }

    @isTest
    static void responseWrapper_isFailureOn500() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(500);
        res.setStatus('Internal Server Error');
        res.setBody('');
        HttpUtils.ResponseWrapper w = new HttpUtils.ResponseWrapper(res);

        Assert.isFalse(w.isSuccess);
        Assert.isTrue(w.errorMessage.contains('500'));
    }

    @isTest
    static void responseWrapper_failureFactory_setsErrorMessage() {
        HttpUtils.ResponseWrapper w = HttpUtils.failure('Timeout occurred');

        Assert.isFalse(w.isSuccess);
        Assert.isNull(w.statusCode);
        Assert.isNull(w.responseBody);
        Assert.areEqual('Timeout occurred', w.errorMessage);
    }

    @isTest
    static void send_returnsSuccessWrapperOn200() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"id":"event1"}'));
        Test.startTest();
        HttpUtils.ResponseWrapper w = HttpUtils.send(
            HttpUtils.buildRequest('GET', 'callout:Google_Calendar_API/test', 5000)
        );
        Test.stopTest();

        Assert.isTrue(w.isSuccess);
        Assert.isTrue(w.responseBody.contains('event1'));
    }

    @isTest
    static void send_returnsFailureWrapperOnCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(true));
        Test.startTest();
        HttpUtils.ResponseWrapper w = HttpUtils.send(
            HttpUtils.buildRequest('GET', 'callout:Google_Calendar_API/test', 5000)
        );
        Test.stopTest();

        Assert.isFalse(w.isSuccess);
        Assert.isTrue(w.errorMessage.contains('Callout failed'));
    }

    @isTest
    static void send_returnsFailureWrapperOn404() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(404, '{"error":"not found"}'));
        Test.startTest();
        HttpUtils.ResponseWrapper w = HttpUtils.send(
            HttpUtils.buildRequest('GET', 'callout:Google_Calendar_API/test', 5000)
        );
        Test.stopTest();

        Assert.isFalse(w.isSuccess);
        Assert.areEqual(404, w.statusCode);
    }
}
