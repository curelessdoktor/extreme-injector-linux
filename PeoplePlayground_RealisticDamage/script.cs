using System.Collections.Generic;
using UnityEngine;

namespace Mod
{
    public class Mod
    {
        public static void Main()
        {
            ModAPI.Register(
                new Modification()
                {
                    OriginalItem = ModAPI.FindSpawnable("Person"),
                    NameOverride = "Person - RealisticDamage",
                    DescriptionOverride = "Realistic damage, organ failure (heart, lungs, brain, liver, kidneys), internal bleeding, severe pain & shock. Much more lethal and simulation-like.",
                    CategoryOverride = ModAPI.FindCategory("People"),
                    AfterSpawn = (Instance) =>
                    {
                        var person = Instance.GetComponentInChildren<PersonBehaviour>();
                        if (person != null && person.gameObject.GetComponent<RealisticDamageBehaviour>() == null)
                        {
                            person.gameObject.AddComponent<RealisticDamageBehaviour>();
                        }
                    }
                }
            );
        }
    }

    /// <summary>
    /// Applies realistic damage multipliers and adds organ system to a person.
    /// </summary>
    public class RealisticDamageBehaviour : MonoBehaviour
    {
        private PersonBehaviour _person;
        private bool _applied;
        private OrganSystemBehaviour _organSystem;

        private void Start()
        {
            _person = GetComponent<PersonBehaviour>();
            if (_person == null) return;

            ApplyRealisticDamageTuning();
            _organSystem = gameObject.AddComponent<OrganSystemBehaviour>();
            _applied = true;
        }

        private void ApplyRealisticDamageTuning()
        {
            if (_person?.Limbs == null) return;

            foreach (var limb in _person.Limbs)
            {
                if (limb == null || limb.PhysicalBehaviour == null) continue;

                // More lethal damage multipliers (realistic: bullets and impacts hurt a lot)
                limb.ShotDamageMultiplier = 2.5f;
                limb.ImpactDamageMultiplier = 2.2f;
                limb.ImpactPainMultiplier = 1.8f;

                // Bones break more easily (realistic fragility)
                limb.BreakingThreshold = Mathf.Max(50f, limb.BreakingThreshold * 0.4f);

                // Less regeneration for realism (body doesn't heal in seconds)
                limb.RegenerationSpeed = Mathf.Max(0f, limb.RegenerationSpeed * 0.15f);

                // More sensitive to G-forces (passing out / damage from impacts)
                limb.GForcePassoutThreshold = Mathf.Max(8f, limb.GForcePassoutThreshold * 0.55f);
                limb.GForceDamageThreshold = Mathf.Max(4f, limb.GForceDamageThreshold * 0.5f);

                // Head and torso are more critical
                if (limb.RoughClassification == LimbBehaviour.BodyPart.Head)
                {
                    limb.ShotDamageMultiplier *= 1.6f;
                    limb.ImpactDamageMultiplier *= 1.5f;
                    limb.IsLethalToBreak = true;
                }
                else if (limb.RoughClassification == LimbBehaviour.BodyPart.Torso)
                {
                    limb.ShotDamageMultiplier *= 1.4f;
                    limb.ImpactDamageMultiplier *= 1.3f;
                }

                // Bleed more from wounds
                var circ = limb.CirculationBehaviour;
                if (circ != null)
                {
                    circ.BloodLossRateMultiplier = Mathf.Max(1f, (circ.BloodLossRateMultiplier + 1.5f) * 1.2f);
                }
            }
        }
    }

    /// <summary>
    /// Simulates organ failure: heart, lungs, brain, liver, kidneys.
    /// Ties consciousness, oxygen, and bleeding to organ state.
    /// </summary>
    public class OrganSystemBehaviour : MonoBehaviour
    {
        private PersonBehaviour _person;
        private float _organUpdateTimer;
        private const float OrganUpdateInterval = 0.2f;

        // Simulated organ health (0 = failed, 1 = healthy). Game already has brain/lungs on limbs; we add torso "organs".
        private float _heartEfficiency = 1f;
        private float _liverEfficiency = 1f;
        private float _kidneyEfficiency = 1f;
        private bool _hasPuncturedLung;
        private bool _severeTorsoDamage;

        private void Start()
        {
            _person = GetComponent<PersonBehaviour>();
        }

        private void Update()
        {
            if (_person == null || _person.Limbs == null) return;
            if (!_person.IsAlive()) return;

            _organUpdateTimer += Time.deltaTime;
            if (_organUpdateTimer < OrganUpdateInterval) return;
            _organUpdateTimer = 0f;

            UpdateOrganState();
            ApplyOrganFailureEffects();
        }

        private void UpdateOrganState()
        {
            float totalBlood = 0f;
            float heartRate = 0f;
            bool hasPump = false;
            float torsoHealthSum = 0f;
            int torsoCount = 0;
            _hasPuncturedLung = false;

            foreach (var limb in _person.Limbs)
            {
                if (limb == null) continue;

                var circ = limb.CirculationBehaviour;
                if (circ != null)
                {
                    totalBlood += circ.GetAmountOfBlood();
                    if (circ.IsPump)
                    {
                        hasPump = true;
                        heartRate = circ.GetHeartRate();
                        // Heart "efficiency" drops when this limb (heart) is damaged
                        float limbHealth = limb.Health / Mathf.Max(0.01f, limb.InitialHealth);
                        _heartEfficiency = Mathf.Clamp01(limbHealth * 1.2f);
                    }
                }

                if (limb.HasLungs && limb.LungsPunctured)
                    _hasPuncturedLung = true;

                if (limb.RoughClassification == LimbBehaviour.BodyPart.Torso)
                {
                    float h = limb.Health / Mathf.Max(0.01f, limb.InitialHealth);
                    torsoHealthSum += h;
                    torsoCount++;
                }
            }

            // Liver/kidneys simulated from torso health
            if (torsoCount > 0)
            {
                float avgTorso = torsoHealthSum / torsoCount;
                _liverEfficiency = Mathf.Lerp(_liverEfficiency, Mathf.Clamp01(avgTorso + 0.2f), 0.08f);
                _kidneyEfficiency = Mathf.Lerp(_kidneyEfficiency, Mathf.Clamp01(avgTorso + 0.15f), 0.08f);
            }

            if (!hasPump)
                _heartEfficiency = 0f;

            _severeTorsoDamage = torsoCount > 0 && (torsoHealthSum / torsoCount) < 0.35f;
        }

        private void ApplyOrganFailureEffects()
        {
            // Oxygen loss from punctured lung
            if (_hasPuncturedLung && _person.OxygenLevel > 0.01f)
            {
                _person.OxygenLevel = Mathf.MoveTowards(_person.OxygenLevel, 0f, 0.015f);
            }

            // Heart failure: less blood flow → consciousness and shock
            if (_heartEfficiency < 0.3f)
            {
                _person.Consciousness = Mathf.MoveTowards(_person.Consciousness, 0f, 0.02f);
                _person.ShockLevel = Mathf.MoveTowards(_person.ShockLevel, 1f, 0.015f);
            }
            else if (_heartEfficiency < 0.7f)
            {
                _person.Consciousness = Mathf.MoveTowards(_person.Consciousness, 0.4f, 0.01f);
                _person.ShockLevel = Mathf.MoveTowards(_person.ShockLevel, 0.6f, 0.008f);
            }

            // Severe torso damage → internal bleeding (increase pain and shock, drain consciousness)
            if (_severeTorsoDamage)
            {
                _person.AddPain(0.02f);
                _person.ShockLevel = Mathf.MoveTowards(_person.ShockLevel, 1f, 0.01f);
                _person.Consciousness = Mathf.MoveTowards(_person.Consciousness, 0f, 0.008f);
                // Apply internal bleeding to torso limbs
                foreach (var limb in _person.Limbs)
                {
                    if (limb != null && limb.RoughClassification == LimbBehaviour.BodyPart.Torso &&
                        limb.CirculationBehaviour != null)
                    {
                        limb.CirculationBehaviour.InternalBleedingIntensity =
                            Mathf.MoveTowards(limb.CirculationBehaviour.InternalBleedingIntensity, 0.5f, 0.02f);
                    }
                }
            }

            // Liver/kidney "failure" → slower recovery, more susceptibility to shock (represented as extra pain retention)
            if (_liverEfficiency < 0.4f || _kidneyEfficiency < 0.4f)
            {
                _person.PainLevel = Mathf.MoveTowards(_person.PainLevel, Mathf.Max(_person.PainLevel, 0.7f), 0.005f);
                _person.ShockLevel = Mathf.MoveTowards(_person.ShockLevel, 1f, 0.004f);
            }

            // Broken bones cause ongoing pain and minor internal bleeding at break site
            foreach (var limb in _person.Limbs)
            {
                if (limb == null || !limb.Broken) continue;
                _person.AddPain(0.008f);
                if (limb.CirculationBehaviour != null && limb.CirculationBehaviour.InternalBleedingIntensity < 0.25f)
                {
                    limb.CirculationBehaviour.InternalBleedingIntensity =
                        Mathf.MoveTowards(limb.CirculationBehaviour.InternalBleedingIntensity, 0.25f, 0.01f);
                }
            }
        }
    }
}

