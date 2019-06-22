#pragma once
#include <EntitasPP\Pool.h>
#include <EntitasPP\ISystem.h>
#include <Singleton\Singleton.h>
#include <LuaBridge\RefCountedPtr.h>

namespace Chestnut {
	namespace Ball {
		class JoinSystem : public EntitasPP::ISystem, public EntitasPP::ISetRefPoolSystem {
		protected:

		public:
		
			JoinSystem() = default;
			virtual ~JoinSystem() {}

			void SetPool(RefCountedPtr< EntitasPP::Pool> pool);

			void Join(int index);

			void Leave(int index);

		protected:
			RefCountedPtr<EntitasPP::Pool> _pool;

		};
	}
}
