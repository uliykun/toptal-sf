@isTest
public class MockHttpCallout implements HttpCalloutMock {

    private final Integer statusCode;
    private final String  body;
    private final Boolean shouldThrow;

    public MockHttpCallout(Integer statusCode, String body) {
        this.statusCode  = statusCode;
        this.body        = body;
        this.shouldThrow = false;
    }

    public MockHttpCallout(Boolean shouldThrow) {
        this.statusCode  = 0;
        this.body        = '';
        this.shouldThrow = shouldThrow;
    }

    public HttpResponse respond(HttpRequest req) {
        if (shouldThrow) {
            throw new System.CalloutException('Simulated network failure');
        }
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setStatus(statusCode >= 200 && statusCode < 300 ? 'OK' : 'Error');
        res.setBody(body != null ? body : '');
        return res;
    }
}
