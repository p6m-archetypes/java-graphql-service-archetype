package {{ root_package }}.graphql;

import {{ group_id }}.persistence.Item;
import {{ group_id }}.persistence.ItemRepository;

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
public class ItemGraphqlController {

    public record ItemView(String id, String displayName) {
    }

    private final ItemRepository repository;

    public ItemGraphqlController(ItemRepository repository) {
        this.repository = repository;
    }

    private static ItemView toView(Item item) {
        return new ItemView(item.getId(), item.getDisplayName());
    }

    @QueryMapping
    public ItemView {{ entityName }}(@Argument("id") String id) {
        return repository.findById(id).map(ItemGraphqlController::toView).orElse(null);
    }

    @QueryMapping
    public List<ItemView> {{ entityName }}s() {
        return repository.findAll().stream().map(ItemGraphqlController::toView).toList();
    }

    @MutationMapping
    public ItemView create{{ EntityName }}(@Argument("displayName") String displayName) {
        return toView(repository.save(new Item(displayName)));
    }

    @MutationMapping
    public ItemView update{{ EntityName }}(@Argument("id") String id, @Argument("displayName") String displayName) {
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
