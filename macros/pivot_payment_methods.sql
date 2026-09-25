{% macro pivot_payment_methods() %}
    {% for method in var('payment_methods') %}
        sum(
            case
                when payment_method = '{{ method }}'
                then amount_cents
                else 0
            end
        ) as {{ method }}_cents
        {% if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}