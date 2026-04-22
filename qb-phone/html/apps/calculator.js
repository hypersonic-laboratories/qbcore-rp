const CalculatorApp = {
    template: `
        <div class="calc-screen">
            <div class="calc-display-area">
                <button type="button" aria-label="Back to home" class="calc-back-button" @click="onBack">
                    <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                </button>
                <div class="calc-display">{{ calcDisplay }}</div>
            </div>
            <div class="calc-buttons">
                <button type="button" class="calc-btn calc-btn-fn" @click="calcClear()">AC</button>
                <button type="button" class="calc-btn calc-btn-fn" @click="calcToggleSign()">+/−</button>
                <button type="button" class="calc-btn calc-btn-fn" @click="calcPercent()">%</button>
                <button type="button" class="calc-btn calc-btn-op" :class="{ 'calc-btn-op-active': calcOp === '÷' }" @click="calcSetOp('÷')">÷</button>

                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('7')">7</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('8')">8</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('9')">9</button>
                <button type="button" class="calc-btn calc-btn-op" :class="{ 'calc-btn-op-active': calcOp === '×' }" @click="calcSetOp('×')">×</button>

                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('4')">4</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('5')">5</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('6')">6</button>
                <button type="button" class="calc-btn calc-btn-op" :class="{ 'calc-btn-op-active': calcOp === '−' }" @click="calcSetOp('−')">−</button>

                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('1')">1</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('2')">2</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('3')">3</button>
                <button type="button" class="calc-btn calc-btn-op" :class="{ 'calc-btn-op-active': calcOp === '+' }" @click="calcSetOp('+')">+</button>

                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('0')">0</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcInput('.')">.</button>
                <button type="button" class="calc-btn calc-btn-num" @click="calcBackspace()"><i data-lucide="delete" style="width:1.25rem;height:1.25rem"></i></button>
                <button type="button" class="calc-btn calc-btn-op" @click="calcEquals()">=</button>
            </div>
        </div>
    `,

    emits: ['navigate'],

    setup(props, { emit }) {
        const { ref } = Vue;

        const calcDisplay     = ref('0');
        const calcPrev        = ref(null);
        const calcOp          = ref(null);
        const calcShouldReset = ref(false);

        function calcInput(digit) {
            if (calcShouldReset.value) {
                calcDisplay.value     = digit === '.' ? '0.' : digit;
                calcShouldReset.value = false;
                return;
            }
            if (digit === '.' && calcDisplay.value.includes('.')) return;
            calcDisplay.value = calcDisplay.value === '0' && digit !== '.'
                ? digit
                : calcDisplay.value + digit;
        }

        function calcSetOp(op) {
            calcPrev.value        = parseFloat(calcDisplay.value);
            calcOp.value          = op;
            calcShouldReset.value = true;
        }

        function calcEquals() {
            if (calcOp.value === null || calcPrev.value === null) return;
            const a = calcPrev.value;
            const b = parseFloat(calcDisplay.value);
            const ops = { '+': a + b, '−': a - b, '×': a * b, '÷': b !== 0 ? a / b : 'Error' };
            const result = ops[calcOp.value];
            calcDisplay.value = String(parseFloat(Number.isFinite(result) ? result.toPrecision(10) : result));
            calcPrev.value        = null;
            calcOp.value          = null;
            calcShouldReset.value = true;
        }

        function calcBackspace() {
            if (calcShouldReset.value || calcDisplay.value === 'Error') return;
            const stripped = calcDisplay.value.startsWith('-') ? calcDisplay.value.slice(1) : calcDisplay.value;
            calcDisplay.value = stripped.length <= 1 ? '0' : calcDisplay.value.slice(0, -1);
        }

        function calcClear() {
            calcDisplay.value     = '0';
            calcPrev.value        = null;
            calcOp.value          = null;
            calcShouldReset.value = false;
        }

        function calcToggleSign() {
            if (calcDisplay.value === '0' || calcDisplay.value === 'Error') return;
            calcDisplay.value = calcDisplay.value.startsWith('-')
                ? calcDisplay.value.slice(1)
                : '-' + calcDisplay.value;
        }

        function calcPercent() {
            const val = parseFloat(calcDisplay.value);
            if (!isNaN(val)) calcDisplay.value = String(val / 100);
        }

        function onBack() {
            calcClear();
            emit('navigate', 'home');
        }

        return {
            calcDisplay, calcOp,
            calcInput, calcSetOp, calcEquals, calcBackspace,
            calcClear, calcToggleSign, calcPercent, onBack,
        };
    },
};
