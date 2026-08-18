package {{ root_package }}.graphql;

import {{ group_id }}.persistence.{{ EntityName }};
import {{ group_id }}.persistence.{{ EntityName }}Repository;

import java.util.List;

import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/**
 * The standard CRUD surface (p6m standards S2) over the {@code { id, displayName }} entity,
 * backed by the persistence module. Method names mirror the schema's name-derived fields;
 * unknown ids resolve to {@code null} (queries/update) or {@code false} (delete).
 */
@Controller
public class {{ EntityName }}GraphqlController {

    public record {{ EntityName }}View(String id, String displayName) {
    }

    private final {{ EntityName }}Repository repository;

    public {{ EntityName }}GraphqlController({{ EntityName }}Repository repository) {
        this.repository = repository;
    }

    private static {{ EntityName }}View toView({{ EntityName }} item) {
        return new {{ EntityName }}View(item.getId(), item.getDisplayName());
    }

    @QueryMapping
    public {{ EntityName }}View {{ entityName }}(@Argument("id") String id) {
        return repository.findById(id).map({{ EntityName }}GraphqlController::toView).orElse(null);
    }

    @QueryMapping
    public List<{{ EntityName }}View> {{ entityName }}s() {
        return repository.findAll().stream().map({{ EntityName }}GraphqlController::toView).toList();
    }

    @MutationMapping
    public {{ EntityName }}View create{{ EntityName }}(@Argument("displayName") String displayName) {
        return toView(repository.save(new {{ EntityName }}(displayName)));
    }

    @MutationMapping
    public {{ EntityName }}View update{{ EntityName }}(@Argument("id") String id, @Argument("displayName") String displayName) {
        return repository.findById(id)
                .map(item -> {
                    item.setDisplayName(displayName);
                    return toView(repository.save(item));
                })
                .orElse(null);
    }

    @MutationMapping
    public Boolean delete{{ EntityName }}(@Argument("id") String id) {
        if (!repository.existsById(id)) {
            return false;
        }
        repository.deleteById(id);
        return true;
    }
}
