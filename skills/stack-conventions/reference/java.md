# Java

## Defaults
- Use the project's build tool and Java version. Check `pom.xml` or `build.gradle` before using
  any language feature.
- Records for immutable data carriers when the version allows (16+).
- Constructor injection in Spring. No `@Autowired` on fields.
- `java.time` for dates, `BigDecimal` for money. Never `double` for currency.
- Return an empty collection, never `null`. `Optional` only as a return type, never as a field
  or parameter.
- No Lombok unless the project already uses it.
- Tests: JUnit 5, plus AssertJ or Mockito only if already present.

## Pitfalls
- `@Transactional` does nothing on a method called from inside the same class: the proxy is
  bypassed.
- `BigDecimal.equals` compares scale: `2.0` is not equal to `2.00`. Use `compareTo`.
- JPA lazy relations inside a loop cause N+1 queries. Fetch-join or batch when iterating.
- `@ManyToOne` is eager by default. Set `fetch = LAZY` explicitly.
- Override `equals` and `hashCode` together, never one alone.
- Catch the specific exception. Never swallow one silently. Use try-with-resources for anything
  closeable.
