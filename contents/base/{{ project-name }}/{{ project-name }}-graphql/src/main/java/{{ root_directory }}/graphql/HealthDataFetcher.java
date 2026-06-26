package {{ root_package }}.graphql;

import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class HealthDataFetcher {

    @QueryMapping
    public String health() {
        return "OK";
    }
}
