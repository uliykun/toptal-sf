public class HttpUtils {

    public class ResponseWrapper {
        public final Boolean isSuccess;
        public final Integer statusCode;
        public final String  responseBody;
        public final String  errorMessage;

        public ResponseWrapper(HttpResponse res) {
            this.statusCode   = res.getStatusCode();
            this.responseBody = res.getBody();
            this.isSuccess    = (this.statusCode >= 200 && this.statusCode < 300);
            this.errorMessage = this.isSuccess
                ? null
                : 'HTTP ' + this.statusCode + ': ' + res.getStatus();
        }

        @TestVisible
        ResponseWrapper(String message) {
            this.isSuccess    = false;
            this.statusCode   = null;
            this.responseBody = null;
            this.errorMessage = message;
        }
    }

    public static ResponseWrapper failure(String message) {
        return new ResponseWrapper(message);
    }

    public static HttpRequest buildRequest(String method, String endpoint, Integer timeoutMs) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(endpoint);
        req.setTimeout(timeoutMs);
        req.setHeader('Accept', 'application/json');
        return req;
    }

    public static HttpRequest buildJsonRequest(
            String method, String endpoint, String jsonBody, Integer timeoutMs) {
        HttpRequest req = buildRequest(method, endpoint, timeoutMs);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        return req;
    }

    public static ResponseWrapper send(HttpRequest req) {
        try {
            return new ResponseWrapper(new Http().send(req));
        } catch (System.CalloutException ex) {
            System.debug(LoggingLevel.ERROR, 'HttpUtils.send — callout failed: ' + ex.getMessage());
            return failure('Callout failed: ' + ex.getMessage());
        }
    }
}
