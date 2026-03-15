# diff-driven-development

The visual diff drives my work. Or rather, it gives me control over where the work is headed. It's a quality gate. Any given diff over a "working system Y", if the diff passes muster, means that when it is applied we have "working system Z".

Reviewing a diff is a O(n) where n is the avergae size of a diff. For a codebase of size M (where M >> N) the value proposition is clear. Diff-driven-development (or just version control in general) enables working software systems to scale larger (in a working way) than before

Before, I guess with the Apollo program and before version control, they just tried really really hard and reviewed the codebase over and over again O(M * X), where X is the number of change sets (?). Expensive, but it worked. Whereas most systems pre-version control simply weren't reviewed rigorously or continually (which can be fine).

I love the diff.
